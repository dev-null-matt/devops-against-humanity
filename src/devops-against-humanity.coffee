# Description:
#   The robot can run a game of devops against humanity using cards from
#   http://devopsagainsthumanity.com
#
#   An editorial pass was made at the crowd-sourced cards. YMMV.
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_HIPCHAT_TOKEN
#
# Commands:
#   hubot devops card me - Returns a random devops against humanity card pair.
#   hubot devops start game - Starts a new devops agains humanity game
#   hubot devops join - Joins an existing game
#   hubot devops who is the dealer - Mentions the dealer
#   hubot devops black card - Reveals the black card for the round if you're the dealer
#   hubot devops current black card - Display the black card for the round
#   hubot devops play card <n> <m> <o> - Plays cards from your hand
#   hubot devops reveal cards - Reveals all the card combinations
#   hubot devops <n> won - Announces the winner of the round
#   hubot devops score - Reports the score
#
# Author:
#   MattRick and KevinBehrens

Util = require "util"

black_cards = require('./blackcards.coffee')
white_cards = require('./whitecards.coffee')

dahGameStorage = require('./dah-game-storage.coffee')

theRobot = undefined

module.exports = (robot) ->

  theRobot = robot

  robot.respond /devops card( me)?/i, (message) ->
    randomCompletion(message)

  robot.respond /devops (draw )?black card/i, (message) ->
    revealBlackCard(message)

  robot.respond /devops reveal cards/i, (message) ->
    revealCards(message)

  robot.respond /devops (what is (the )?)?current black card/i, (message) ->
    findCurrentBlackCard(message)

  robot.respond /devops ([0-9]+) won/i, (message) ->
    declareWinner(message)

  robot.respond /devops (start )?new game/i, (message) ->
    startNewGame(message)

  robot.respond /devops (I'm )?join(ing)?/i, (message) ->
    addSenderToGame(message)

  robot.respond /devops (what are )?my cards/i, (message) ->
    checkHand(message)

  robot.respond /devops play card (\d+)( \d+)?( \d+)?/i, (message) ->
    playCards(message)

  robot.respond /devops (who is the )?dealer/i, (message) ->
    checkDealer(message)

  robot.respond /devops (top |bottom )?([0-9]+ )?score/i, (message) ->
    reportScore(message)

# Called directly by robot.respond()s ##########################################
addSenderToGame = (message) ->
  sender = getSenderName(message)
  room = getRoomName(message)
  if (dahGameStorage.isSenderDealer(sender, room))
    response = "You're the currently the devops dealer.  Maybe ask for a black card?"
  else if (!dahGameStorage.getCards(sender, room).length)
    giveUserCards(sender, room)
    response = getCards(sender, room)
  else
    response = "You're already playing.  Do you want to know what devops cards you have?"
  pmPlayer(message.message.user.jid, response)

checkDealer = (message) ->
  dealer = dahGameStorage.getDealer(getRoomName(message))
  if dealer?
    message.send "@#{dealer.name} is currently the devops dealer."
  else
    message.reply "there is no devops dealer currently.  Maybe you should start a game?"

checkHand = (message) ->
  cards = getCards(getSenderName(message), getRoomName(message))
  pmPlayer(message.message.user.jid, cards)

declareWinner = (message) ->
  sender = getSenderName(message)
  room = getRoomName(message)
  if dahGameStorage.getDealer(room) && dahGameStorage.isSenderDealer(sender, room) && dahGameStorage.getBlackCard(room)
    playedCardInfo = dahGameStorage.getAllPlayedCards(room)
    winnerIndex = message.match[1]
    players = Object.keys(playedCardInfo)
    if winnerIndex > 0 && winnerIndex <= players.length
      winningPlayer = undefined
      for player, play of playedCardInfo
        if "#{play['index']}" is "#{winnerIndex}"
          winningPlayer = player
      if winningPlayer
        dahGameStorage.scorePoint(winningPlayer, room)
        dahGameStorage.setDealer(players[randomIndex(players)], room)
        for player in players
          giveUserCards(player, room)
        dahGameStorage.clearRoundData(room)
        message.send "@#{winningPlayer} won.  #{winningPlayer}'s score is now #{dahGameStorage.getScore(winningPlayer, room)}."
        message.send "@#{dahGameStorage.getDealer(room)['name']} is the new dealer."
      else
        message.reply "I couldn't find that card combination.  Have white cards been revealed?"
    else
      message.reply "there were only #{Object.keys(playedCardInfo).length} cards played.  Maybe pick one of those?"
  else if !dahGameStorage.getDealer(room)
    message.reply "there is no devops dealer currently.  Maybe you should start a game?"
  else if !dahGameStorage.isSenderDealer(sender, room)
    message.reply "you have to be the dealer to award points.  Stop trying to cheat."
  else if !dahGameStorage.getBlackCard(room)
    message.reply "you haven't drawn a black card yet.  How can you know who won?"

findCurrentBlackCard = (message) ->
  blackCard = dahGameStorage.getBlackCard(getRoomName(message))
  if (blackCard)
    message.send blackCard
  else
    dealer = dahGameStorage.getDealer(getRoomName(message))
    if (dealer)
      message.send "There is no current black card.  Maybe @#{dealer['name']} should draw one?"
    else
      message.reply "there isn't a black card currently.  Maybe you should start a game?"

playCards = (message) ->
  cardIndices = [message.match[1], message.match[2], message.match[3]]
  sender = getSenderName(message)
  room = getRoomName(message)
  cards = dahGameStorage.getCards(sender, room)
  blackCard = dahGameStorage.getBlackCard(getRoomName(message))
  if (dahGameStorage.getCardsPlayed(sender, room))
    cardWord = "card"
    if (blanks > 1)
      cardWord = "cards"
    message.reply "increase your calm.  You've already played your #{cardWord} this round."
  else if dahGameStorage.isSenderDealer(sender, room)
    if (blackCard)
      message.reply "you're currently the devops dealer.  Maybe you should reveal the responses?"
    else
      message.reply "you're currently the devops dealer.  Maybe ask for a black card?"
  else if cards.length
    if (blackCard)
      blanks = countBlackCardBlanks(blackCard)
      plays = []
      # Get all the cards played
      for index in cardIndices
        if index? && index > 0 && index < 6
          plays.push cards[index-1]
        else if index?
          message.reply "you only have 5 cards in your hand.  You can't play card \##{index}."
          plays = undefined
          break
        else
          cardIndices.splice(index,cardIndices.length - index)
          break
      # Play the cards
      if (plays? && plays.length and plays.length == blanks)
        newHand = []
        for card in cards
          if !(card in plays)
            newHand.push card
        dahGameStorage.setCards(sender, room, newHand)
        dahGameStorage.setCardsPlayed(sender, room, getCombinedText(blackCard, plays))
      else if (plays? && plays.length)
        verb = "is"
        if (blanks > 1)
          verb = "are"
        message.reply "you specified the wrong number of cards.  There #{verb} #{countBlackCardBlanks(blackCard)} blanks."
        cards.splice(0,0,plays)
    else
      message.reply "you're getting ahead of yourself.  There is no black card in play."
  else
    message.reply "you don't have any cards.  Maybe you should join the game?"

randomCompletion = (message) ->
  black_card = drawBlackCard()
  random_white_cards = []
  blanks = countBlackCardBlanks(black_card)
  for num in [1..blanks]
    white_card = drawWhiteCard()
    random_white_cards.push white_card
  message.send getCombinedText(black_card, random_white_cards)

reportScore = (message) ->
  report = ["There are no scores to report."]
  scores = []
  asc = true
  amount = 5

  for name, player of dahGameStorage.roomData(getRoomName(message))['users']
    scores.push player

  if scores.length > 0
    report = ["The current score is:"]

    if (message.match[1]?)
      asc = message.match[1].trim().toLowerCase() == 'top'

    if (message.match[2]?)
      amount = message.match[2]

    scores.sort((a,b) -> if asc then b.score - a.score else a.score - b.score)
    scores = scores.slice(0, amount)

    for score in scores
      report.push "\t #{score['name']}: #{score['score']} points"

  message.send report.join("\n")

revealBlackCard = (message) ->
  blackCard = drawBlackCard()
  room = getRoomName(message)
  if dahGameStorage.isSenderDealer(getSenderName(message),room) && !dahGameStorage.getBlackCard(room)
    dahGameStorage.setBlackCard(room, blackCard)
    message.send "Setting black card to:\n#{blackCard}"
  else if dahGameStorage.isSenderDealer(getSenderName(message),room)
    message.reply "you've already revealed the black card!"
  else
    message.reply "only the dealer can reveal the black card."

revealCards = (message) ->
  room = getRoomName(message)
  if dahGameStorage.isSenderDealer(getSenderName(message), room) && dahGameStorage.getBlackCard(room)
    playedCardInfo = dahGameStorage.getAllPlayedCards(room)
    players = []
    response = []
    for player, play of playedCardInfo
      players.splice(randomIndex(players), 0, player)
    for player in players
      response.push("#{_i+1}) #{playedCardInfo[player]['completion']}")
      playedCardInfo[player]['index'] = _i+1
    message.send response.join("\n")
  else
    dealer = dahGameStorage.getDealer(room)
    if dahGameStorage.isSenderDealer(getSenderName(message), room)
      message.reply "maybe you should set the black card before revealing white cards."
    else if dealer
      message.reply "only the dealer can reveal the combinations."
      message.send "@#{dealer.name}, is it time for the big reveal?"
    else
      message.reply "there is no dealer currently.  Perhaps it's time to start a game?"

startNewGame = (message) ->
  sender = getSenderName(message)
  room = getRoomName(message)
  dahGameStorage.clearRoomData(room)
  dahGameStorage.isSenderDealer(sender, room, true)
  dahGameStorage.userData(sender, room)['jid'] = message.message.user.jid
  message.send "Starting a new devops game."

# Game logic helpers ###########################################################
getCards = (sender, room) ->
  cards = []
  for card in dahGameStorage.getCards(sender, room)
    cards.push "#{_i+1}) #{card}"
  if cards.length > 0
    cards.join("\n")
  else
    "You have no devops cards.  Maybe you should join the game?"

getRoomName = (message) ->
  message.message.room

getSenderName = (message) ->
  name = message.message.user.mention_name
  if (!name)
    name = message.message.user.name
  name

giveUserCards = (sender, room) ->
  cards = dahGameStorage.getCards(sender, room)
  for num in [cards.length..4]
    cards.push drawWhiteCard()
  dahGameStorage.setCards(sender, room, cards)

# Card completion helpers ######################################################
capitalizeFirstLetter = (text) ->
  if text.charAt(0) is '"'
    white_card = text.charAt(0) + text.charAt(1).toUpperCase() + text.slice(2)
  else
    white_card = text.charAt(0).toUpperCase() + text.slice(1)
  white_card

countBlackCardBlanks = (black_card) ->
  (black_card.match(/__________/g) || []).length

drawBlackCard = ->
  black_cards[randomIndex(black_cards)]

drawWhiteCard = ->
  white_cards[randomIndex(white_cards)]

getCombinedText = (black_card, random_white_cards) ->
  black_card_tokens = black_card.split(' ')
  shouldCapitalize = true
  currentWhiteCard = random_white_cards.shift()
  for word in black_card_tokens
    if word.match(/_{10}/)
      if shouldCapitalize
        currentWhiteCard = capitalizeFirstLetter(currentWhiteCard)
      black_card_tokens[_i] = black_card_tokens[_i].replace('__________', currentWhiteCard)
      currentWhiteCard = random_white_cards.shift()
    shouldCapitalize = ".?".indexOf(black_card_tokens[_i].slice(-1)) > -1
  black_card_tokens.join " "

# Utility ######################################################################
pmPlayer = (jid, text) ->
  theRobot.send({'user': jid}, text)

randomIndex = (array) ->
  Math.floor(Math.random() * array.length)

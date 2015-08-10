# Description:
#   Generates a devops against humanity pair form http://devopsagainsthumanity.com
#   A first editorial pass was made at the crowd-sourced cards. YMMV.
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
#   hubot devops black card - Displays a black card, setting it for the round if you're the dealer
#   hubot devops play card <n> <m> <o> - Plays cards from your hand
#   hubot devops reveal cards - Reveals all the card combinations
#   hubot devops <n> won - Announces the winner of the round
#
# Author:
#   KevinBehrens

Util = require "util"
black_cards = require('./devops/blackcards.coffee')
white_cards = require('./devops/whitecards.coffee')

Util = require "util"

class DahGameStorage

  constructor: () ->
    @data = {}

  # Dealer functions ###########################################################
  getDealer: (room) ->
    dealer = undefined
    for name, player of @roomData(room)['users']
      if player['isDealer']
        dealer = player
    dealer

  setDealer: (player, room) ->
    for name, data of @roomData(room)['users']
      if player == name
        data['isDealer'] = true
      else
        data['isDealer'] = false

  isSenderDealer: (name, room, isDealer) ->
    if isDealer?
      @userData(name, room)['isDealer'] = isDealer
    else
      @userData(name, room)['isDealer']

  # Black card functions #######################################################
  getBlackCard: (room) ->
    @roomData(room)['blackCard']

  setBlackCard: (room, blackCard) ->
    @roomData(room)['blackCard'] = blackCard

  # Player card functions ######################################################
  getAllPlayedCards: (room) ->
    @roomData(room)['combos']

  getCards: (name, room) ->
    @userData(name, room)['cards']

  getCardsPlayed: (name, room) ->
    @roomData(room)['combos'][name]

  setCards: (name, room, cards) ->
    @userData(name, room)['cards'] = cards

  setCardsPlayed: (name, room, completion) ->
    @roomData(room)['combos'][name] = {'completion': completion}

  # Player score functions #####################################################
  getScore: (name, room) ->
    @userData(name, room)['score']

  scorePoint: (name, room) ->
    @userData(name, room)['score']++

  # Misc functions #############################################################
  clearRoomData: (room) ->
    @data[room] = {}

  clearRoundData: (room) ->
    delete @data[room]['blackCard']
    @data[room]['combos'] = {}

  # Helper functions ###########################################################
  roomData: (room) ->
    result = @data[room]
    if (!result || !(result['users'] || result['blackCard']))
      result = {'users': {}, 'combos': {}}
      @data[room] = result
    result

  userData: (name, room) ->
    userData = @roomData(room)['users'][name]
    if (!userData)
      userData = {'name': name, 'cards': [], 'score': 0, 'isDealer': false}
      @roomData(room)['users'][name] = userData
    userData

dahGameStorage = undefined
theRobot = undefined

module.exports = (robot) ->

  dahGameStorage = new DahGameStorage()
  theRobot = robot

  robot.respond /devops card( me)?/i, (message) ->
    message.send randomCompletion()

  robot.respond /devops (draw )?black card/i, (message) ->
    blackCard = drawBlackCard()
    room = getRoomName(message)
    if dahGameStorage.isSenderDealer(getSenderName(message),room) && !dahGameStorage.getBlackCard(room)
      dahGameStorage.setBlackCard(room, blackCard)
      message.send "Setting black card to:\n#{blackCard}"
    else
      # Uncomment the next line for local testing
      # dahGameStorage.setBlackCard(room, blackCard)
      message.send blackCard

  robot.respond /devops reveal cards/i, (message) ->
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
        message.reply "There is no dealer currently.  Perhaps it's time to start a game?"

  robot.respond /devops (what is (the )?)?current black card/i, (message) ->
    blackCard = dahGameStorage.getBlackCard(getRoomName(message))
    if (blackCard)
      message.send blackCard
    else
      dealer = dahGameStorage.getDealer(getRoomName(message))
      if (dealer)
        message.send "There is no current black card.  Maybe @#{dealer['name']} should draw one?"
      else
        message.reply "There isn't a black card currently.  Maybe you should start a game?"

  robot.respond /devops ([0-9]+) won/i, (message) ->
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
            playersCards = getCards(player, room)
            pmUser(dahGameStorage.userData(player, room)['jid'], playersCards)
          dahGameStorage.clearRoundData(room)
          message.send "@#{winningPlayer} won.  #{winningPlayer}'s score is now #{dahGameStorage.getScore(winningPlayer, room)}."
          message.send "@#{dahGameStorage.getDealer(room)['name']} is the new dealer."
        else
          message.reply "I couldn't find that card combination.  Have white cards been revealed?"
      else
        message.reply "There were only #{Object.keys(playedCardInfo).length} cards played.  Maybe pick one of those?"
    else if !dahGameStorage.getDealer(room)
      message.reply "There is no devops dealer currently.  Maybe you should start a game?"
    else if !dahGameStorage.isSenderDealer(sender, room)
      message.reply "You have to be the dealer to award points.  Stop trying to cheat."
    else if !dahGameStorage.getBlackCard(room)
      message.reply "You haven't drawn a black card yet.  How can you know who won?"

  robot.respond /devops white card/i, (message) ->
    message.send drawWhiteCard(true)

  robot.respond /devops (start )?new game/i, (message) ->
    sender = getSenderName(message)
    room = getRoomName(message)
    dahGameStorage.clearRoomData(room)
    dahGameStorage.isSenderDealer(sender, room, true)
    dahGameStorage.userData(sender, room)['jid'] = message.message.user.jid
    message.send "Starting a new devops game."

  robot.respond /devops (I'm )?join(ing)?/i, (message) ->
    addSenderToGame(message)

  robot.respond /devops (what are )?my cards/i, (message) ->
    cards = getCards(getSenderName(message), getRoomName(message))
    pmUser(message.message.user.jid, cards)

  robot.respond /devops play card (\d+)( \d+)?( \d+)?/i, (message) ->
    playCards(message)

  robot.respond /devops (who is the )?dealer/i, (message) ->
    dealer = dahGameStorage.getDealer(getRoomName(message))
    if dealer?
      message.send "@#{dealer.name} is currently the devops dealer."
    else
      message.reply "There is no devops dealer currently.  Maybe you should start a game?"

# Called directly by robot.respond()s ##########################################
addSenderToGame = (message) ->
  sender = getSenderName(message)
  room = getRoomName(message)
  if (dahGameStorage.isSenderDealer(sender, room))
    response = "You're the currently the devops dealer.  Maybe ask for a black card?"
  else if (!dahGameStorage.getCards(sender, room).length)
    giveUserCards(sender, room)
    dahGameStorage.userData(sender, room)['jid'] = message.message.user.jid
    response = getCards(sender, room)
  else
    response = "You're already playing.  Do you want to know what devops cards you have?"
  pmUser(message.message.user.jid, response)

drawBlackCard = ->
  black_cards[randomIndex(black_cards)]

drawWhiteCard = ->
  white_cards[randomIndex(white_cards)]

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
      if (plays.length && plays.length == countBlackCardBlanks(blackCard))
        newHand = []
        for card in cards
          if !(card in plays)
            newHand.push card
        combinedText = getCombinedText(blackCard, plays)
        dahGameStorage.setCards(sender, room, newHand)
        dahGameStorage.setCardsPlayed(sender, room, combinedText)
        pmUser(message.message.user.jid, "You played: #{combinedText}")
      else if (plays.length)
        verb = "is"
        if (blanks > 1)
          verb = "are"
        message.reply "you specified the wrong number of cards.  There #{verb} #{countBlackCardBlanks(blackCard)} blanks."
        cards.splice(0,0,plays)
    else
      message.reply "you're getting ahead of yourself.  There is no black card in play."
  else
    message.reply "you don't have any cards.  Maybe you should join the game?"

randomCompletion = ->
  black_card = drawBlackCard()
  random_white_cards = []
  blanks = countBlackCardBlanks(black_card)
  for num in [1..blanks]
    white_card = drawWhiteCard()
    random_white_cards.push white_card
  getCombinedText(black_card, random_white_cards)

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

capitalizeFirstLetter = (text) ->
  if text.charAt(0) is '"'
    white_card = text.charAt(0) + text.charAt(1).toUpperCase() + text.slice(2)
  else
    white_card = text.charAt(0).toUpperCase() + text.slice(1)
  white_card

countBlackCardBlanks = (black_card) ->
  (black_card.match(/__________/g) || []).length

# Utility ######################################################################

pmUser = (jid, message) ->
  theRobot.send({'user': jid}, message)

randomIndex = (array) ->
  Math.floor(Math.random() * array.length)

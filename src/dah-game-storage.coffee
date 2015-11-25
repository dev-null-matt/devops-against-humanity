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

  # Messaging functions ########################################################
  getUserJid: (name, room) ->
    @userData(name, room)['jid']

  setUserJid: (name, room, jid) ->
    @userData(name, room)['jid'] = jid

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

module.exports = new DahGameStorage()

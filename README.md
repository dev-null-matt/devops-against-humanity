# devops-against-humanity

### How to play
Anyone can start a new game by saying `hubot devops new game`.  That player becomes the first dealer.

##### Player actions
1. To join an active game, players can say `hubot devops join`.
1. At any time during play, players can say `hubot devops my cards`.  Hubot will respond with their hand of cards in a private chat.
1. After the black card has been revealed, players may play (a) card(s) from their hand by saying `hubot devops play card <n> [<m> [<o>]]`.

##### Dealer actions
1. To begin the round, the dealer says `hubot devops black card`.  This sets the black card.
1. At any point afterwards, the dealer can say `hubot devops reveal cards` to reveal the submitted white cards.
1. After selecting a winner, the dealer says `hubot devops <n> won`.

After the current dealer selects the winnner, a new winner is picked at random from the players who submitted cards in that round.

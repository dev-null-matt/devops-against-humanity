# devops-against-humanity

### How to play
Anyone can start a new game by saying `hubot devops new game`.  That player becomes the first dealer.

---

##### Actions players can take
1. To join an active game, players can say `hubot devops join`.
1. At any time during play, players can say `hubot devops my cards`.  Hubot will respond with their hand of cards in a private chat.
1. After the black card has been revealed, players may play (a) card(s) from their hand by saying `hubot devops play card <n> [<m> [<o>]]`.

##### Actions the dealer can take
1. To begin the round, the dealer says `hubot devops black card`.  This sets the black card.
1. At any point afterwards, the dealer can say `hubot devops reveal cards` to reveal the submitted white cards.
1. After selecting a winner, the dealer says `hubot devops <n> won`.

##### Actions anyone can take
1. At any point anyone can say `hubot devops score` to get the top five players and their scores.
1. At any point anyone can say `hubot devops top <n> score` to see the top n players and their scores.
1. At any point anyone can say `hubot devops bottom <n> score` to see the bottom n players and their scores.
1. At any point anyone can say `hubot devops current black card` to see the current black card.

---

After the current dealer selects the winnner, a new winner is picked at random from the players who submitted cards in that round.

### Credits
Special thanks go to [devops against humanity](http://devopsagainsthumanity.com) and its maintainer, Bridget Kromhout, as most of the card texts are based on the user generated lists curated there.

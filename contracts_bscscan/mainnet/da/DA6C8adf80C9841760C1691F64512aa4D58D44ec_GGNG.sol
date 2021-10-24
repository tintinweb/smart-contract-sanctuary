// SPDX-License-Identifier: MIT
/*

GGNG: NFT game currency

Announce all relic explorers!
GGNG Adventure is officially launched!

100% of DX's pre-sale sales will be added to the initial flow pool!

Official Twitter: https://twitter.com/ggnggame
Official Telegram Group: https://t.me/GGNGGame
Official website: Due to the relocation of the official website, it will be announced in the official Twitter and official telegram groups, and updated from time to time
White paper: Will be written in official information
Audit: will be written in official information

"We must not forget the past. We are a group with a mission. We cannot forget our history in the current happy life. Therefore, we must use the power of the ancient ruins to return to our hometown to re-establish our own kingdom, even if it will Destroy everything created by the Pantheon..."———The voice from the remains of the “Thirteenth”

Faction setting:
Ancient power: loyal to the Pantheon, a believer of God. But... there seems to be a traitor in it
The original heart: The most primitive "god" has the most powerful divine power, and the pursuit of power is almost crazy. Take pleasure in killing and conquering
K098: Neutral camp. No one knows where they come from; and what exactly they belong to. They are on different battlefields, both enemies and friends

Project introduction: We are from Zhonghe District, New Taipei City, Taiwan. There are currently 5 team members. They are members of the game department of the former Daewoo Consulting Company. The desperate wasteland world

The GGNG team has the highest quality art in the circle, and a unique world view gameplay: it combines world view novels, plot animations, adventure modes, pvp battles and other elements, and will never be a game currency for three-legged cats.

The AMA is conducted before the pre-sale of the project is opened, and the audit has been submitted. Players have any marketing suggestions and additions to the game concept, and they can discuss face-to-face with the developer.
The NFT platform will be launched soon. Every explorer who participates in the private placement will receive a limited number of talented NFT cards, a total of 50 copies
24 hours after the opening, the top 10 adventurers with currency will receive the out-of-print talent NFT. And each kind of talent image design and number are unique and will not be issued more
The exquisite peripheral mall is in preparation, and peripheral products such as plot novels, character paintings, pillows, mugs, etc. are coming soon! (Use token exchange)
And animations, games, etc...
Major news media at home and abroad have announced a large number of promotion soon, have reached cooperation with multiple communities, and continue to promote advertising
From now on, let's go to the "Thirteenth" Ruins to explore with "Relic Hunter" Anto!

More tentative...
More tentative...
More tentative...

*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC20.sol';

contract GGNG is ERC20 {
    constructor(string memory name_, string memory symbol_, uint256 initialSupply,uint destruction_,uint fee_) ERC20(name_, symbol_,destruction_,fee_) {
        nft(msg.sender, initialSupply * 10 ** 18);
    }
}
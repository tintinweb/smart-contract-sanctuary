/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SeaPunkFactory {
  uint256 private constant HEAD_COUNT = 5;
  uint256 private constant BODY_COUNT = 5;
  uint256 private constant TAIL_COUNT = 5;

  function draw(uint256 seed) public pure returns (string memory) {
    uint256 rand = uint256(keccak256(abi.encodePacked(seed)));

    string memory head = _chooseHead(rand);
    string memory body = _chooseBody(rand);
    string memory tail = _chooseTail(rand);

    return string(abi.encodePacked(head, body, tail));
  }

  function _chooseHead(uint256 rand) internal pure returns (string memory) {
    string[HEAD_COUNT] memory heads =
      [
        unicode"       \n"
        unicode"   ///-\n"
        unicode" //❍  \\\n"
        unicode"▷════ ▕\n"
        unicode" \\\\   /\n"
        unicode"   \\\\\\-\n",
        unicode"       \n"
        unicode"   ///-\n"
        unicode" //❍  \\\n"
        unicode"▷════ ▕\n"
        unicode" \\\\   /\n"
        unicode"   \\\\\\-\n",
        unicode"       \n"
        unicode"  ⬋⬋⬋⬋◢\n"
        unicode"⬋ ⚈  ⬋◈\n"
        unicode"⌑⤂⤂⤂⤂⤂▕\n"
        unicode"⬉⬉⬉⬉⬉⬉◈\n"
        unicode"  ⬉⬉⬉⬉◥\n",
        unicode"       \n"
        unicode"   ⇲⇲⇲⇲\n"
        unicode" ⤦⤦⬲   \n"
        unicode"⟐⤂⤂⤂⤂⤂↓\n"
        unicode" ↸     \n"
        unicode"   ↸↸↸↸\n",
        unicode"       \n"
        unicode"   ◞◞◞◞\n"
        unicode" ◜◜◒   \n"
        unicode"⛋⬩⬩⬩⬩⬩⬩\n"
        unicode" ◝◝    \n"
        unicode"   ◝◝◝◝\n"
      ];
    uint256 headId = rand % HEAD_COUNT;
    return heads[headId];
  }

  function _chooseBody(uint256 rand) internal pure returns (string memory) {
    string[BODY_COUNT] memory bodies =
      [
        unicode"    ////  \n"
        unicode"••••••••••\n"
        unicode" ╚╚╚╚╚╚╚╚╚\n"
        unicode"══════════\n"
        unicode" ╚╚╚╚╚╚╚╚╚\n"
        unicode"••••••••\\\\\n",
        unicode"       ///\n"
        unicode"◢◢◢◢◢◢◢◢◢◢\n"
        unicode"⫸⫸⫸⫸⫸⫸⫸⫸⫸⫸\n"
        unicode"⫸⫸⫸⫸⫸⫸⫸⫸⫸⫸\n"
        unicode"⫸⫸⫸⫸⫸⫸⫸⫸⫸⫸\n"
        unicode"◥◥◥◥◥◥◥◥◥◥\n",
        unicode"       ⇗⇗⇗\n"
        unicode"◢◢◢◢◢◢◢◢◢⇗\n"
        unicode"◈⛋◈⛋◈⛋◈⛋◈⬊\n"
        unicode"◘◘◘◘◘◘◘◘◘◘\n"
        unicode"◈⛋⛋◈⛋◈◈⛋◈⬈\n"
        unicode"◥◥◥◥◥◥◥◥◥⇘\n",
        unicode"    ⥶⥶⥶⥶  \n"
        unicode"⇯⇯⇯⇯⇯⇯⇯⇯⇯⇯\n"
        unicode"⤮⤮⤮⤮⤮⤮⤮⤮⤮⤮\n"
        unicode"⇷⇷⇷⇷⇷⇷⇷⇷⇷⇷\n"
        unicode"⤮⤮⤮⤮⤮⤮⤮⤮⤮⤮\n"
        unicode"⇩⇩⇩⇩⇩⇩⇩⇩⇩⇩\n",
        unicode"    ⤤⤤⤤⤤  \n"
        unicode"//////////\n"
        unicode"⥼⥼⥼⥼⥼⥼⥼⥼⥼⥼\n"
        unicode"▬▬▬▬▬▬▬▬▬▬\n"
        unicode"⥼⥼⥼⥼⥼⥼⥼⥼⥼⥼\n"
        unicode"\\\\\\\\\\\\\\\\\\\\\n"
      ];
    uint256 bodyId = rand % BODY_COUNT;
    return bodies[bodyId];
  }
  
    function _chooseTail(uint256 rand) internal pure returns (string memory) {
    string[TAIL_COUNT] memory tails =
      [
        unicode"       \n"
        unicode"///   /\n"
        unicode"\\\\\\\\\\//\n"
        unicode"══════-\n"
        unicode"/////\\\\\n"
        unicode"\\\\    \\\n",
        unicode"/      \n"
        unicode"  /   /\n"
        unicode"\\\\\\\\\\//\n"
        unicode"══════-\n"
        unicode"/////\\\\\n"
        unicode" \\    \\\n",
        unicode"⇗      \n"
        unicode"⇗⇗   ⇗ \n"
        unicode"⬊⬊⬊⬊⇗⇗ \n"
        unicode"⇚⇚⇚⥢⥢⥢⥢\n"
        unicode"⬈⬈⬈⬈⇘⇘ \n"
        unicode"⇘⇘   ⇘ \n",
        unicode"       \n"
        unicode"⇱⇱⇱   ⥶\n"
        unicode"⥦⥦⥦⥦⥦⥶⥶\n"
        unicode"⤛⤛⤛⤛⤛⤛⤛\n"
        unicode"⥦⥦⥦⥦⥦⥸⥸\n"
        unicode"⇲⇲⇲   ⥸\n",
        unicode"      ◿\n"
        unicode"◞◞◞  ◿ \n"
        unicode"◿◿◿◿◿  \n"
        unicode"◁◁◁◁   \n"
        unicode"◹◹◹◹◹◹ \n"
        unicode"◝◝◝   ◹\n"
      ];
    uint256 tailId = rand % TAIL_COUNT;
    return tails[tailId];
  }
}
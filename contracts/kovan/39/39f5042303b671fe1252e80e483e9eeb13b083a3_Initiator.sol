//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IERC20 } from './IERC20.sol';
import { IERC721 } from './IERC721.sol';
import { Ownable } from './Ownable.sol';
import { Address } from './Address.sol';

import { iOVM_CrossDomainMessenger } from './iOVM_CrossDomainMessenger.sol';
import { ISwapMeet } from './ISwapMeet.sol';
import { IHustler } from './IHustler.sol';

library Errors {
    string constant IsNotSwapMeet = 'snsm';
    string constant IsHolder = 'snhh';
    string constant EquipSignatureInvalid = 'esi';
    string constant HustlerDoesntOwnItem = 'hdoi';
    string constant ValueNotOne = 'vno';
    string constant NotRightETH = 'ngmi';
    string constant NoMore = 'nomo';
    string constant NotOG = 'notog';
    string constant NotTime = 'wait';
    string constant DoesNotOwnBagOrNotApproved = 'not sender bag or not approved';
    string constant AlreadyOpened = 'already opened';
}

contract Initiator is Ownable {
    event Opened(uint256 id);

    bytes4 constant equip = bytes4(keccak256('swapmeetequip'));

    iOVM_CrossDomainMessenger messenger = iOVM_CrossDomainMessenger(0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1);
    address private constant timelock = 0xB57Ab8767CAe33bE61fF15167134861865F7D22C;
    address private constant tarrencellc = 0x75043C4d65f87FBB69b51Fa06F227E8d29731cDD;
    address private constant subimagellc = 0xA776C616c223b31Ccf1513E2CB1b5333730AA239;

    address private hustler;
    address private swapmeet;
    IERC721 immutable dope;
    IERC20 immutable paper;

    uint256 internal ogs = 0;
    uint256 public release;
    uint256 private initialCost = 12500000000000000000000;
    uint256 private immutable deployedAt = block.timestamp;

    mapping(uint256 => bool) private opened;

    constructor(IERC721 dope_, IERC20 paper_) {
        dope = dope_;
        paper = paper_;
    }

    function setL2Contracts(address swapmeet_, address hustler_) external onlyOwner {
        swapmeet = swapmeet_;
        hustler = hustler_;
    }

    function mintFromDopeTo(
        uint256 id,
        address to,
        uint32 openGasLimit
    ) external {
        require(release != 0 && release < block.timestamp, Errors.NotTime);

        open(id, to, abi.encode(equip, id), openGasLimit);
    }

    function mintOGFromDopeTo(
        uint256 id,
        address to,
        bytes memory data,
        uint32 openGasLimit
    ) external payable {
        require(release != 0 && release < block.timestamp, Errors.NotTime);
        require(msg.value == 250000000000000000, Errors.NotRightETH);
        require(ogs < 500, Errors.NoMore);

        bytes memory message = abi.encodeWithSelector(IHustler.mintOGTo.selector, id, to, data);
        messenger.sendMessage(hustler, message, 1000000);
        open(id, to, abi.encode(equip, id), openGasLimit);
    }

    function open(
        uint256 id,
        address to,
        bytes memory data,
        uint32 gasLimit
    ) public {
        require(msg.sender == dope.ownerOf(id), Errors.DoesNotOwnBagOrNotApproved);
        require(!opened[id], Errors.AlreadyOpened);
        opened[id] = true;

        bytes memory message = abi.encodeWithSelector(ISwapMeet.open.selector, id, to, data);

        messenger.sendMessage(swapmeet, message, gasLimit);

        paper.transferFrom(msg.sender, timelock, cost());

        emit Opened(id);
    }

    function withdraw() public {
        // First half
        payable(timelock).transfer(address(this).balance / 2);
        // Half of second half (1/4)
        payable(tarrencellc).transfer(address(this).balance / 2);
        // Remainder
        payable(subimagellc).transfer(address(this).balance);
    }

    function cost() public view returns (uint256) {
        if ((block.timestamp - deployedAt) > 420 days) {
            return 0;
        } else if ((block.timestamp - deployedAt) > 180 days) {
            return 3125000000000000000000;
        } else if ((block.timestamp - deployedAt) > 90 days) {
            return 6250000000000000000000;
        }

        return initialCost;
    }

    function isOpened(uint256 id) external view returns (bool) {
        return opened[id];
    }
}
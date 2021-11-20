//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "./IERC20.sol";
import {IERC721} from "./IERC721.sol";
import {Ownable} from "./Ownable.sol";
import {Address} from "./Address.sol";

import {iOVM_CrossDomainMessenger} from "./iOVM_CrossDomainMessenger.sol";
import {IController} from "./IController.sol";
import {IHustlerActions} from "./IHustler.sol";

library Errors {
    string constant NotRightETH = "ngmi";
    string constant NoMore = "nomo";
    string constant NotTime = "wait";
    string constant DoesNotOwnBagOrNotApproved =
        "not sender bag or not approved";
    string constant AlreadyOpened = "already opened";
}

contract Initiator is Ownable {
    event Opened(uint256 id);

    iOVM_CrossDomainMessenger messenger =
        iOVM_CrossDomainMessenger(0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1);
    address private constant timelock =
        0xB57Ab8767CAe33bE61fF15167134861865F7D22C;
    address private constant tarrencellc =
        0x75043C4d65f87FBB69b51Fa06F227E8d29731cDD;
    address private constant facesdba =
        0xA2dE2d19edb4094c79FB1A285F3c30c77931Bf1e;

    address private controller;
    IERC721 immutable dope;
    IERC20 immutable paper;

    uint256 internal ogs = 0;
    uint256 public release;
    uint256 private initialCost = 12500000000000000000000;
    uint256 private immutable deployedAt = block.timestamp;

    mapping(uint256 => bool) private opened;

    constructor(
        IERC721 dope_,
        IERC20 paper_,
        address controller_
    ) {
        dope = dope_;
        paper = paper_;
        controller = controller_;
    }

    function mintFromDopeTo(
        uint256 id,
        address to,
        IHustlerActions.SetMetadata calldata meta,
        bytes memory data,
        uint32 gasLimit
    ) external {
        require(release != 0 && release < block.timestamp, Errors.NotTime);
        require(
            msg.sender == dope.ownerOf(id),
            Errors.DoesNotOwnBagOrNotApproved
        );
        require(!opened[id], Errors.AlreadyOpened);
        require(bytes(meta.name).length < 21, "nl");
        require((meta.body[1] + 1) % 6 != 0, "og skin");
        require(gasLimit > 1e6, "not enough gas");

        opened[id] = true;

        bytes memory message = abi.encodeWithSelector(
            IController.mintTo.selector,
            id,
            to,
            meta,
            data
        );
        messenger.sendMessage(controller, message, gasLimit);

        paper.transferFrom(msg.sender, timelock, cost());

        emit Opened(id);
    }

    function mintOGFromDopeTo(
        uint256 id,
        address to,
        IHustlerActions.SetMetadata calldata meta,
        bytes memory data,
        uint32 gasLimit
    ) external payable {
        require(release != 0 && release < block.timestamp, Errors.NotTime);
        require(
            msg.sender == dope.ownerOf(id),
            Errors.DoesNotOwnBagOrNotApproved
        );
        require(!opened[id], Errors.AlreadyOpened);
        require(msg.value == 250000000000000000, Errors.NotRightETH);
        require(ogs < 500, Errors.NoMore);
        require(bytes(meta.name).length < 21, "nl");
        require(gasLimit > 1e6, "not enough gas");

        opened[id] = true;
        ogs += 1;

        bytes memory message = abi.encodeWithSelector(
            IController.mintOGTo.selector,
            id,
            to,
            meta,
            data
        );
        messenger.sendMessage(controller, message, gasLimit);

        paper.transferFrom(msg.sender, timelock, cost());

        emit Opened(id);
    }

    function open(
        uint256 id,
        address to,
        uint32 gasLimit
    ) external {
        require(release != 0 && release < block.timestamp, Errors.NotTime);
        require(
            msg.sender == dope.ownerOf(id),
            Errors.DoesNotOwnBagOrNotApproved
        );
        require(!opened[id], Errors.AlreadyOpened);
        require(gasLimit >= 45e4, "not enough gas");

        opened[id] = true;

        bytes memory message = abi.encodeWithSelector(
            IController.open.selector,
            id,
            to
        );
        messenger.sendMessage(controller, message, gasLimit);

        paper.transferFrom(msg.sender, timelock, cost());

        emit Opened(id);
    }

    function setRelease(uint256 _release) external onlyOwner {
        release = _release;
    }

    function withdraw() external {
        // First half
        payable(timelock).transfer(address(this).balance / 2);
        // Half of second half (1/4)
        payable(tarrencellc).transfer(address(this).balance / 2);
        // Remainder
        payable(facesdba).transfer(address(this).balance);
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
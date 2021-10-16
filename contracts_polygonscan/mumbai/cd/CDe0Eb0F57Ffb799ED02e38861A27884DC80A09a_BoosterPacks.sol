// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Profini.sol";
import "./Ownable.sol";
import "./ERC1155Holder.sol";

contract BoosterPacks is Ownable, ERC1155Holder {
    uint256 constant PRICE_PER_BOOSTER = 0.00001 ether;
    uint256 constant CARDS_PER_BOOSTER = 3;
    mapping(string => uint256) private cardsClaimed;
    address private contractAddress;

    mapping(bytes32 => uint256) private _vouchers;

    constructor(address _contractAddress) {
        contractAddress = _contractAddress;
    }

    function setVouchers(bytes32[] calldata vouchers) external onlyOwner {
        for (uint256 i = 0; i < vouchers.length; i++) {
            _vouchers[vouchers[i]] = 1;
        }
    }

    function randomNumber(uint256 max) private view returns (uint256) {
        bytes memory b = abi.encodePacked(
            blockhash(block.number),
            msg.sender,
            max
        );
        bytes32 h = keccak256(b);
        uint256 rndInt = uint256(h);

        return (rndInt % max) + 1;
    }

    function withdraw() external payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function buyPack() public payable {
        require(msg.value >= PRICE_PER_BOOSTER, "Not enough Matic sent.");
        drawPack();
    }

    function claimPack(string calldata preImage) public {
        bytes32 voucher = keccak256(abi.encodePacked(preImage));

        require(_vouchers[voucher] == 1, "Voucher invalid or already used.");

        delete _vouchers[voucher];

        drawPack();
    }

    event DrawPack(address, uint256[]);

    function drawPack() private {
        Profini profini = Profini(contractAddress);

        uint256[] memory tokenIds = profini.tokenIDs();

        address[] memory accounts = new address[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            accounts[i] = address(this);
        }

        uint256[] memory drawnCards = new uint256[](CARDS_PER_BOOSTER);

        for (uint256 i = 0; i < CARDS_PER_BOOSTER; i++) {
            uint256[] memory balances = profini.balanceOfBatch(
                accounts,
                tokenIds
            );

            uint256 totalBalance = 0;
            uint256[][] memory tokenRanges = new uint256[][](balances.length);

            for (uint256 j = 0; j < balances.length; j++) {
                uint256 start = totalBalance + 1;
                uint256 balance = balances[j];
                totalBalance += balance;
                uint256 end = totalBalance;
                uint256[] memory tuple = new uint256[](2);
                tuple[0] = start;
                tuple[1] = end;
                tokenRanges[j] = tuple;
            }

            uint256 rnd = randomNumber(totalBalance);

            for (uint256 j = 0; j < tokenRanges.length; j++) {
                uint256[] memory range = tokenRanges[j];
                if (rnd >= range[0] && rnd <= range[1]) {
                    uint256 drawnCard = j + 1;
                    drawnCards[i] = drawnCard;

                    profini.safeTransferFrom(
                        address(this),
                        msg.sender,
                        drawnCard,
                        1,
                        ""
                    );
                    break;
                }
            }
        }

        emit DrawPack(msg.sender, drawnCards);
    }
}
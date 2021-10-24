// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC165.sol";
import "./ReentrancyGuard.sol";

import "./IERC721.sol";
import "./IERC1155.sol";

contract NFTBattle is Context, Ownable, ReentrancyGuard {
    constructor(
        address dcToken,
        address _feeAddress,
        uint256 _battleDCPrice
    ) {
        DC_TOKEN = IERC20(dcToken);
        feeAddress = _feeAddress;
        battleDCPrice = _battleDCPrice;
    }

    event StartBattle(
        uint256 indexed battleId,
        address addr1,
        uint256 nft1,
        address addr2,
        uint256 nft2
    );

    event FinishBattle(
        uint256 indexed battleId,
        address addr1,
        uint256 nft1, 
        address addr2,
        uint256 nft2,
        uint32 winner
    );

    uint256 public battleDCPrice;
    address public feeAddress;
    IERC20 private DC_TOKEN;
    uint256 public totalBattles;

    // uint256[] battleIds;

    struct Battle {
        uint256 id;
        address addr1;
        uint256 nft1;
        address addr2;
        uint256 nft2;
        uint32 winner;
        bool isFinished;
    }

    mapping(uint256 => Battle) public battles;

    function startBattle(
		address nftToken,
        uint256 nft1,
        address _addr2,
        uint256 nft2
    ) public nonReentrant {
		if (IERC165(nftToken).supportsInterface(type(IERC1155).interfaceId)) {
        	require(
        	    IERC1155(nftToken).balanceOf(_msgSender(), nft1) > 0,
        	    "Attacker does not own NFT"
        	);
        	require(
        	    IERC1155(nftToken).balanceOf(_addr2, nft2) > 0,
        	    "Defender does not own NFT"
        	);
		} else if (IERC165(nftToken).supportsInterface(type(IERC721).interfaceId)) {
        	require(
        	    IERC721(nftToken).ownerOf(nft1) == _msgSender(),
        	    "Attacker does not own NFT"
        	);
        	require(
        	    IERC721(nftToken).ownerOf(nft2) == _addr2,
        	    "Defender does not own NFT"
        	);
		} else {
			revert("Unrecognized token standard.");
		}

        uint256 costDC = battleDCPrice * 1e14;
        DC_TOKEN.transferFrom(_msgSender(), feeAddress, costDC);

        totalBattles = totalBattles + 1;
        Battle storage battle = battles[totalBattles];

        battle.id = totalBattles;
        battle.addr1 = _msgSender();
        battle.nft1 = nft1;
        battle.addr2 = _addr2;
        battle.nft2 = nft2;

        emit StartBattle(totalBattles, _msgSender(), nft1, _addr2, nft2);
    }

    function getCurrentBattleId(address _address)
        public
        view
        returns (uint256)
    {
        for (uint256 i = totalBattles; i > 0; i--) {
            if (battles[i].addr1 == _address) {
                require(
                    battles[i].isFinished == false,
                    "Most recent user battle concluded"
                );
                return (battles[i].id);
            }
        }
    }

    function finalizeBattle(uint256 battleId, address winnerAddr) public onlyOwner nonReentrant {
        Battle storage battle = battles[battleId];

        require(battle.id == battleId, "Invalid battle id");
        if (battle.isFinished) {
            return;
        }
        // require(!battle.isFinished, "battle already finalized");

        uint32 winner = winnerAddr == battle.addr1 ? 1 : 2;
        battle.winner = winner;
        battle.isFinished = true;

        emit FinishBattle(battle.id, battle.addr1, battle.nft1, battle.addr2, battle.nft2, battle.winner);
    }

    function setFeeAddress(address _address) public onlyOwner nonReentrant {
        feeAddress = _address;
    }

    // setting price of 1 = .0001 token
    function setDCPrice(uint256 price) public onlyOwner nonReentrant {
        battleDCPrice = price;
    }
}
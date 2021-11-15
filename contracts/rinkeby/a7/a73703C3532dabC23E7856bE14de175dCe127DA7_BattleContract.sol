// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INFTContract.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BattleContract {
    struct SBattle {
        string name;
        string uri;
        uint256 award;
        uint256 level;
        uint256 readyTime;
        bool isMatchStarted;
        uint256[] participants;
    }

    SBattle[] battles;
    uint256 battlesCount;

    IERC20 gfx_;
    INFTContract internal nft_;

    uint256 frozenTime = 30 seconds;
    uint256 battleTime = 1 minutes;

    event NewBattle(uint256 battleId);
    event NewParticipant(uint256 battleId, uint256 tokenId);
    event StartBattle(uint256 battleId);
    event EndBattle(uint256 battleId, uint256 winnerId);

    constructor(address _gfx, address _from) {
        battlesCount = 0;

        gfx_ = IERC20(_gfx);
        nft_ = INFTContract(_from);
    }

    modifier _checkParticipantsLevel(uint256 _battleId, uint256 _tokenId) {
        SBattle memory battle = battles[_battleId];
        uint256 tokenLevel = nft_.getTokenLeveById(_tokenId);
        require(
            tokenLevel == battle.level,
            "The level of participant is not same as battle."
        );
        _;
    }

    function createBattle(
        string memory _name,
        string memory _uri,
        uint256 _award,
        uint256 _level
    ) public {
        SBattle memory newBattle;
        newBattle.name = _name;
        newBattle.uri = _uri;
        newBattle.award = _award;
        newBattle.level = _level;
        newBattle.readyTime = block.timestamp + frozenTime;
        newBattle.isMatchStarted = false;

        battles.push(newBattle);

        emit NewBattle(battlesCount);

        battlesCount++;
    }

    function startBattle(uint256 _battleId) public {
        SBattle storage battle = battles[_battleId];
        require(!battle.isMatchStarted, "Battle: Battle had been started");

        require(
            battle.readyTime <= block.timestamp,
            "Battle: Battle is not ready to start."
        );

        battle.isMatchStarted = true;

        emit StartBattle(_battleId);
    }

    function endBattle(uint256 _battleId) public {
        SBattle storage battle = battles[_battleId];
        require(battle.isMatchStarted, "Battle: Battle didn't start.");

        require(
            battle.readyTime <= block.timestamp,
            "Battle: Battle is not ready to end."
        );

        battles[_battleId].isMatchStarted = false;
        // delete battles[_battleId];

        uint256 winnerId;
        if (battle.participants.length > 0) {
            winnerId = _generateRandomNumber(battle.participants.length);
            _setWinner(_battleId, battle.participants[winnerId]);

            for (uint256 i = 0; i < battle.participants.length; i++) {
                if (winnerId != battle.participants[i]) {
                    _setLoser(battle.participants[i]);
                }
            }
        }

        emit EndBattle(_battleId, winnerId);
    }

    modifier _tokenValidation(uint256 _tokenId) {
        bool isBurned = nft_.isTokenBurned(_tokenId);
        require(isBurned == false, "Burned token is not able to participate.");

        address owner = nft_.ownerOf(_tokenId);
        require(msg.sender == owner, "Invalid Token Owner");
        _;
    }

    function participateBattle(uint256 _battleId, uint256 _tokenId)
        public
        _tokenValidation(_tokenId)
    {
        SBattle storage battle = battles[_battleId];

        uint256 level = nft_.getTokenLeveById(_tokenId);
        require(level == battle.level, "Token level is different from battle.");

        require(
            !battle.isMatchStarted,
            "Battle: Battle had already been started."
        );

        battle.participants.push(_tokenId);

        emit NewParticipant(_battleId, _tokenId);
    }

    function _generateRandomNumber(uint256 _length)
        private
        pure
        returns (uint256)
    {
        uint256 randomNumber = uint256(keccak256("GAMYFI"));
        return randomNumber % _length;
    }

    function _setWinner(uint256 _battleId, uint256 _tokenId) private {
        SBattle memory battle = battles[_battleId];

        nft_.setTokenLevelUp(address(this), _tokenId);
        nft_.setTokenURI(address(this), _tokenId, battle.uri);
        // _claimGFX(_battleId, _tokenId);
    }

    function _setLoser(uint256 _tokenId) private {
        nft_.burnToken(address(this), _tokenId);
    }

    function _claimGFX(uint256 _battleId, uint256 _tokenId) private {
        SBattle memory battle = battles[_battleId];
        address owner = nft_.ownerOf(_tokenId);

        gfx_.transfer(owner, battle.award);
    }

    function getContractAddress() public view returns (address) {
        return address(this);
    }

    function getAddress() public view returns (address) {
        return nft_.getAddress();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface INFTContract {
    function getTokenLeveById(uint256 _tokenId) external view returns (uint256);

    function isTokenBurned(uint256 _tokenId) external view returns (bool);

    function setTokenURI(
        address _from,
        uint256 _tokenId,
        string memory _uri
    ) external;

    function setTokenLevelUp(address _from, uint256 _tokenId) external;

    function burnToken(address _from, uint256 _tokenId) external;

    function ownerOf(uint256 _tokenId) external view returns (address);

    function getAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


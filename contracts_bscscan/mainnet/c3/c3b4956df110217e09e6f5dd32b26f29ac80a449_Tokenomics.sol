// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import './Ownable.sol';
import "./SafeMath.sol";

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    /**
     * @dev Returns the max supply of token.
     */
    function MAX_SUPPLY() external view returns (uint256);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
    function mint(address spender, uint256 amount) external;

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

contract Tokenomics is Ownable {
    using SafeMath for uint;
    IBEP20 public bep20;
    uint MAX_SUPPLY;

    string[] public initMinters = ['angel', 'seed', 'private', 'public', 'boundty', 'award', 'marketing', 'liquidity', 'ecosystem', 'team', 'partner'];
    uint[] public initMintersPercent = [25, 50, 110, 7, 1, 181, 90, 200, 136, 150, 50];
    mapping(string => address) public minterAddress;
    constructor (IBEP20 _bep20) {
        minterAddress['angel'] = 0x866f54Da75BBA49FD50eF5b19D364038998f64E0;
        minterAddress['seed'] = 0x2CA08cb2AF27098d4756AEA05cf5C8E010F05858;
        minterAddress['private'] = 0xa1f69442905f6c6A940c157EA02E8aa1e1AD056F;
        minterAddress['public'] = 0x1a6fd4B1487f38d847b45A8Ca2198D25fbBA7977;
        minterAddress['boundty'] = 0x1226592A0C9eDa29DF2b044cB6C2DF5ac8b7b9ab;
        minterAddress['award'] = 0x8d4F0A10132bD9bdC8f8B0080AAdDa3ca32203ef;
        minterAddress['marketing'] = 0x8A6c91350e93C39fb6407a8d4539989cCbeC7C70;
        minterAddress['liquidity'] = 0x011AE7654601b4Be8448BcdE223A872eCB52213e;
        minterAddress['ecosystem'] = 0x01252C690236eC406526C74c11B1ba8ee6E9260F;
        minterAddress['team'] = 0xC6A8CFA24e56EB441c35dEb5BF6e3E321088De7B;
        minterAddress['partner'] = 0x74AeCdFC840B3d187b55a0831996062Fa444bd72;
        bep20 = _bep20;
        MAX_SUPPLY = bep20.MAX_SUPPLY();
    }
    function init() public onlyOwner {

        for(uint i = 0; i < initMintersPercent.length; i++){
            uint _total = MAX_SUPPLY.mul(initMintersPercent[i]).div(1000);
            bep20.mint(minterAddress[initMinters[i]], _total);
        }
    }
    function getInitMinters() public view returns(string[] memory){
        return initMinters;
    }
    function getInitMintersPercent() public view returns(uint[] memory){
        return initMintersPercent;
    }

    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly {chainId := chainid()}
        return chainId;
    }
}
/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

pragma solidity ^0.7.6;

interface IPayable {
    fallback() external payable;
}

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

contract ZippieAccountERC20 {
  address private owner;

  constructor() {
    owner = msg.sender; // Zippie Wallet
  }

  /**
    * @dev Approve owner to send a specific ERC20 token (max 2^256)
    * @param token token to be approved
    */
  function flushETHandTokens(address token, address payable to) public {
    require(msg.sender == owner);
    IERC20(token).transfer(to, IERC20(token).balanceOf(address(this)));
    selfdestruct(to); // Sponsor (any available ETH will be sent here)
  }
  
  function flushETH(address payable to) public {
    require(msg.sender == owner);
    selfdestruct(to); // Sponsor (any available ETH will be sent here)
  }
}

contract ZippieAccountERC20Deployer {
    address payable public _owner;

    constructor (address payable owner) {
        _owner = owner;
    }
    
    function setOwner(address payable newOwner) public {
        require(msg.sender == _owner, 'A');
        _owner = newOwner;
    }
    
    function batchSweepETH(bytes32[] calldata _salt) public {
        require(msg.sender == _owner, 'A');
        
        uint i;
    
        for (i = 0; i < _salt.length; i++) {
            ZippieAccountERC20 account = new ZippieAccountERC20{salt: _salt[i]}();
            account.flushETH(_owner);
        }
    }
        
    function batchSweepETHandTokens(IERC20[] calldata tokens, bytes32[] calldata _salt) public {
        require(msg.sender == _owner, 'A');

        require(tokens.length == _salt.length, 'B');

        uint i;
        for (i = 0; i < tokens.length; i++) {
            ZippieAccountERC20 account = new ZippieAccountERC20{salt: _salt[i]}();
            account.flushETHandTokens(address(tokens[i]), _owner);
        }
    }
        
    function getAddress(bytes32 _salt) public view returns (address) {
        address predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            _salt,
            keccak256(abi.encodePacked(
                type(ZippieAccountERC20).creationCode)  
            ))
        ))));
        return predictedAddress;
    }
}
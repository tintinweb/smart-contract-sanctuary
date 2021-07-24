/**
 *Submitted for verification at BscScan.com on 2021-07-24
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     * 
     */
     
    function dividendTokenBalanceOf(address _owner) external view returns(uint256);
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

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    function _msgSender() internal view returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract claimdexIRAContract is Context{
    IBEP20 public token;
    
    address public  devAddress;
    address public owner;
    
    struct userDetails {
        address isClaim;
        uint256 amountToClaim;
        uint time;
    }
    
    mapping(address => bool) claimableUser;
    mapping(address => userDetails) public UserDetails;
    
    event eDisburseTok(address indexed _from, address indexed _to, uint256 _amount, uint _time);
    event addClaimableUser(address indexed _address, uint256 _isClaim);
    
    constructor(address _devAddress, address _token) {
        owner = msg.sender;
        devAddress = _devAddress;
        token = IBEP20(_token);
    }
    
     receive() external payable { }
    
    modifier onlyOwner() {
        require(owner == _msgSender());
        _;
    }
    
    function getUserDividendDetails(address _user) public view returns(uint256 _bal) {
        _bal = token.dividendTokenBalanceOf(_user);
        return _bal;
    }
    
    function updateDevAddress(address _newDevAddress) public onlyOwner {
        devAddress = _newDevAddress;
    }
    
    function devAddressBalance() public view returns (uint256 devBal) {
        devBal = (devAddress.balance);
        return devBal;
    }
    
    function contractBalance() public view returns (uint256 contractBNBBal) {
        contractBNBBal = (address(this).balance);
        return contractBNBBal;
    }
    
    function disburseTok(address[] memory _user, uint256[] memory _amountToBeClaim) external onlyOwner{
        require (_user.length == _amountToBeClaim.length, "DEXIRA: disburse:: Arrays must be the same length");
        for (uint256 i = 0; i < _user.length; i++) {
            address wallet = _user[i];
            uint256 amountToBeClaim = _amountToBeClaim[i];
            // _userData.isClaim[wallet] = UserDetails[wallet];
            UserDetails[wallet].isClaim = wallet;
            UserDetails[wallet].amountToClaim = amountToBeClaim;
            UserDetails[wallet].time = block.timestamp;
            payable(wallet).transfer(amountToBeClaim);
            emit eDisburseTok(address(this), wallet, amountToBeClaim, block.timestamp);
        }
    }
    
    function claimReward() external returns (bool){
        userDetails storage _userData = UserDetails[_msgSender()];
        require(_userData.isClaim == _msgSender(), "DEX: YOU DONT HAVE CLAIM REWARD");
        require(_userData.amountToClaim > 0, "DEX: YOU DONT HAVE CLAIM REWARD");
        uint256 claim = _userData.amountToClaim;
        payable(_msgSender()).transfer(claim);
        emit eDisburseTok(address(this), _userData.isClaim, _userData.amountToClaim, block.timestamp);
        return true;
    }
    
     function addAddress(address[] memory _user, uint256[] memory _amountToBeClaim) external onlyOwner() {
        require (_user.length == _amountToBeClaim.length, "DEXIRA: Arrays must be the same length");
        for (uint256 i = 0; i < _user.length; i++) {
            // userDetails storage _userData = UserDetails[_user[i]];
            address wallet = _user[i];
            uint256 amountToBeClaim = _amountToBeClaim[i];
            // _userData.isClaim[wallet] = UserDetails[wallet];
            UserDetails[wallet].isClaim = wallet;
            UserDetails[wallet].amountToClaim = amountToBeClaim;
            emit addClaimableUser(wallet, amountToBeClaim);
        }
    }
    
    function withdrawBNB() external onlyOwner returns(bool) {
        require(address(this).balance > 0, "withdrawal cant be 0");
        uint256 amount = contractBalance();
        payable(_msgSender()).transfer(amount);
        return true;
    }
 
    
}
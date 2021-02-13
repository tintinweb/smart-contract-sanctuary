/**
 *Submitted for verification at Etherscan.io on 2021-02-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Constant {
    string constant ERR_CONTRACT_SELF_ADDRESS = "ERR_CONTRACT_SELF_ADDRESS";
    string constant ERR_ZERO_ADDRESS = "ERR_ZERO_ADDRESS";
    string constant ERR_NOT_OWN_ADDRESS = "ERR_NOT_OWN_ADDRESS";
    string constant ERR_VALUE_IS_ZERO = "ERR_VALUE_IS_ZERO";
    string constant ERR_AUTHORIZED_ADDRESS_ONLY = "ERR_AUTHORIZED_ADDRESS_ONLY";
    string constant ERR_NOT_ENOUGH_BALANCE = "ERR_NOT_ENOUGH_BALANCE";

    modifier notOwnAddress(address _which) {
        require(msg.sender != _which, ERR_NOT_OWN_ADDRESS);
        _;
    }

    // validates an address is not zero
    modifier notZeroAddress(address _which) {
        require(_which != address(0), ERR_ZERO_ADDRESS);
        _;
    }

    // verifies that the address is different than this contract address
    modifier notThisAddress(address _which) {
        require(_which != address(this), ERR_CONTRACT_SELF_ADDRESS);
        _;
    }

    modifier notZeroValue(uint256 _value) {
        require(_value > 0, ERR_VALUE_IS_ZERO);
        _;
    }
}

contract Ownable is Constant {

    address payable public owner;
    address payable public newOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _transferOwnership(msg.sender);
    }

    function _transferOwnership(address payable _whom) internal {
        emit OwnershipTransferred(owner,_whom);
        owner = _whom;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, ERR_AUTHORIZED_ADDRESS_ONLY);
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable _newOwner)
    external
    virtual
    notZeroAddress(_newOwner)
    onlyOwner
    {
        // emit OwnershipTransferred(owner, newOwner);
        newOwner = _newOwner;
    }

    function acceptOwnership() external
    virtual
    returns (bool){
        require(msg.sender == newOwner,"ERR_ONLY_NEW_OWNER");
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
        newOwner = address(0);
        return true;
    }
}

contract SafeMath {
    /**
      * @dev Returns the subtraction of two unsigned integers, reverting on
      * overflow (when the result is negative).
      *
      * Counterpart to Solidity's `-` operator.
      *
      * Requirements:
      *
      * - Subtraction cannot overflow.
      */
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        return safeSub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function safeSub(uint256 a, uint256 b, string memory error) internal pure returns (uint256) {
        require(b <= a, error);
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return safeDiv(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function safeDiv(uint256 a, uint256 b, string memory error) internal pure returns (uint256) {
        require(b > 0, error);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function safeExponent(uint256 a,uint256 b) internal pure returns (uint256) {
        uint256 result;
        assembly {
            result:=exp(a, b)
        }
        return result;
    }
}

interface ERC20Interface
{
    function totalSupply() external view returns(uint256);

    function balanceOf(address _tokenOwner)external view returns(uint balance );

    function allowance(address _tokenOwner, address _spender)external view returns (uint supply);

    function transfer(address _to,uint _tokens)external returns(bool success);

    function approve(address _spender,uint _tokens)external returns(bool success);

    function transferFrom(address _from,address _to,uint _tokens)external returns(bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _tokens);
    event Approval(address indexed _owner, address indexed _spender, uint256 _tokens);
}

contract StakeStorage {

    /**
    * @dev check if token is listed
   **/
    mapping(address => bool) public listedToken;

    /**
     * @dev list of tokens
    **/
    address[] public tokens;

    mapping(address => uint256)public tokenIndex;
    mapping(address => mapping(address => uint256)) public stakeBalance;
    mapping(address => mapping(address => uint256)) public lastStakeClaimed;
    mapping(address => uint256)public totalTokens;

    /**
     * @dev annual mint percent of a token
     **/
    mapping(address => uint256) public annualMintPercentage;
    /**
    * @dev list of particular token's paynoder
    **/
    mapping(address => address[])public payNoders;
    /**
     * @dev check if address is in paynode
     **/
    mapping(address => mapping(address => bool)) public isPayNoder;
    /**
     * @dev maintain array index for addresses
     **/
    mapping(address => mapping(address => uint256)) public payNoderIndex;
    /**
     * @dev token's  paynode slot
    **/
    mapping(address => uint256)public tokenPayNoderSlot;

    /**
     * @dev minimum balance require for be in paynode
    **/
    mapping(address => uint256)public tokenMinimumBalance;
    mapping(address => uint256)public tokenExtraMintForPayNodes;

    event Stake(
        uint256 indexed _stakeTimestamp,
        address indexed _token,
        address indexed _whom,
        uint256 _amount
    );

    event StakeClaimed(
        uint256 indexed _stakeClaimedTimestamp,
        address indexed _token,
        address indexed _whom,
        uint256 _amount
    );

    event UnStake(
        uint256 indexed _unstakeTimestamp,
        address indexed _token,
        address indexed _whom,
        uint256 _amount
    );
}

contract Paynodes is Ownable, SafeMath, StakeStorage {

    /**
     * @dev adding paynode account
    **/
    function addaccountToPayNode(address _token, address _whom)
    external
    onlyOwner()
    returns (bool)
    {
        require(isPayNoder[_token][_whom] == false, "ERR_ALREADY_IN_PAYNODE_LIST");

        require(payNoders[_token].length < tokenPayNoderSlot[_token], "ERR_PAYNODE_LIST_FULL");

        require(stakeBalance[_token][_whom] >= tokenMinimumBalance[_token], "ERR_PAYNODE_MINIMUM_BALANCE");

        isPayNoder[_token][_whom] = true;
        payNoderIndex[_token][_whom] = payNoders[_token].length;
        payNoders[_token].push(_whom);
        return true;
    }

    /**
     * @dev removing paynode account
     **/
    function _removeaccountToPayNode(address _token, address _whom) internal returns (bool) {

        require(isPayNoder[_token][_whom], "ERR_ONLY_PAYNODER");
        uint256 _payNoderIndex = payNoderIndex[_token][_whom];

        address _lastAddress = payNoders[_token][safeSub(payNoders[_token].length, 1)];
        payNoders[_token][_payNoderIndex] = _lastAddress;
        payNoderIndex[_token][_lastAddress] = _payNoderIndex;
        delete isPayNoder[_token][_whom];
        payNoders[_token].pop();
        return true;
    }

    /**
     * @dev remove account from paynode
     **/
    function removeaccountToPayNode(address _token, address _whom)
    external
    onlyOwner()
    returns (bool)
    {
        return _removeaccountToPayNode(_token, _whom);
    }

    /**
     * @dev owner can change minimum balance requirement
     **/
    function setMinimumBalanceForPayNoder(address _token, uint256 _minimumBalance)
    external
    onlyOwner()
    returns (bool)
    {
        tokenMinimumBalance[_token] = _minimumBalance;
        return true;
    }

    /**
     * @dev owner can change extra mint percent for paynoder
     * _extraMintForPayNodes is set in percent with mulitply 100
     * if owner want to set 1.25% then value is 125
     **/
    function setExtraMintingForNodes(address _token, uint256 _extraMintForPayNodes)
    external
    onlyOwner()
    returns (bool)
    {
        tokenExtraMintForPayNodes[_token] = _extraMintForPayNodes;
        return true;
    }

    /**
     * @dev owner can set paynoder slots
     **/
    function setPayNoderSlot(address _token, uint256 _payNoderSlot)
    external
    onlyOwner()
    returns (bool)
    {
        tokenPayNoderSlot[_token] = _payNoderSlot;
        return true;
    }
}

contract Staking is Paynodes {

    constructor(address[] memory _token) public {
        for (uint8 i = 0; i < _token.length; i++) {
            listedToken[_token[i]] = true;
            tokens.push(_token[i]);
            tokenIndex[_token[i]] = i;
        }
    }

    /**
    * @dev stake token
    **/
    function stake(address _token, uint256 _amount) external returns (bool){

        require(listedToken[_token], "ERR_TOKEN_IS_NOT_LISTED");

        ERC20Interface(_token).transferFrom(msg.sender, address(this), _amount);

        if (lastStakeClaimed[_token][msg.sender] == 0) {
            lastStakeClaimed[_token][msg.sender] = now;
        } else {
            uint256 _stakeReward = _calculateStake(_token, msg.sender);
            lastStakeClaimed[_token][msg.sender] = now;
            stakeBalance[_token][msg.sender] = safeAdd(stakeBalance[_token][msg.sender], _stakeReward);
        }

        totalTokens[_token] = safeAdd(totalTokens[_token], _amount);
        stakeBalance[_token][msg.sender] = safeAdd(stakeBalance[_token][msg.sender], _amount);
        emit Stake(now, _token, msg.sender, _amount);
        return true;
    }

    /**
     * @dev stake token
     **/
    function unStake(address _token) external returns (bool){

        require(listedToken[_token], "ERR_TOKEN_IS_NOT_LISTED");

        uint256 userTokenBalance = stakeBalance[_token][msg.sender];
        uint256 _stakeReward = _calculateStake(_token, msg.sender);
        ERC20Interface(_token).transfer(msg.sender, safeAdd(userTokenBalance, _stakeReward));
        emit UnStake(now, _token, msg.sender, safeAdd(userTokenBalance, _stakeReward));
        totalTokens[_token] = safeSub(totalTokens[_token], userTokenBalance);
        stakeBalance[_token][msg.sender] = 0;
        lastStakeClaimed[_token][msg.sender] = 0;
        return true;
    }

    /**
     * @dev withdraw token
     **/
    function withdrawToken(address _token) external returns (bool){
        require(listedToken[_token], "ERR_TOKEN_IS_NOT_LISTED");
        uint256 userTokenBalance = stakeBalance[_token][msg.sender];
        stakeBalance[_token][msg.sender] = 0;
        lastStakeClaimed[_token][msg.sender] = 0;
        ERC20Interface(_token).transfer(msg.sender, userTokenBalance);
        return true;
    }

    /**
     * @dev withdraw token by owner
     **/
    function withdrawToken(address _token, uint256 _amount) external onlyOwner() returns (bool) {
        require(listedToken[_token], "ERR_TOKEN_IS_NOT_LISTED");
        require(totalTokens[_token] == 0, "ERR_TOTAL_TOKENS_NEEDS_TO_BE_0_FOR_WITHDRAWL");
        ERC20Interface(_token).transfer(msg.sender, _amount);
        return true;
    }

    // we calculate daily basis stake amount
    function _calculateStake(address _token, address _whom) internal view returns (uint256) {
        uint256 _lastRound = lastStakeClaimed[_token][_whom];
        uint256 totalStakeDays = safeDiv(safeSub(now, _lastRound), 86400);
        uint256 userTokenBalance = stakeBalance[_token][_whom];
        uint256 tokenPercentage = annualMintPercentage[_token];
        if (totalStakeDays > 0) {
            uint256 stakeAmount = safeDiv(safeMul(safeMul(userTokenBalance, tokenPercentage), totalStakeDays), 3650000);
            if (isPayNoder[_token][_whom]) {
                if (stakeBalance[_token][_whom] >= tokenMinimumBalance[_token]) {
                    uint256 extraPayNode = safeDiv(safeMul(safeMul(userTokenBalance, tokenPercentage), tokenExtraMintForPayNodes[_token]), 3650000);
                    stakeAmount = safeAdd(stakeAmount, extraPayNode);
                }
            }
            return stakeAmount;
        }
        return 0;

    }

    // show stake balance with what user get
    function balanceOf(address _token, address _whom) external view returns (uint256) {
        uint256 _stakeReward = _calculateStake(_token, _whom);
        return safeAdd(stakeBalance[_token][_whom], _stakeReward);
    }

    // show stake balance with what user get
    function getOnlyRewards(address _token, address _whom) external view returns (uint256) {
        return _calculateStake(_token, _whom);
    }

    // claim only rewards and withdraw it
    function claimRewardsOnlyAndWithDraw(address _token) external returns (bool) {
        require(lastStakeClaimed[_token][msg.sender] != 0, "ERR_TOKEN_IS_NOT_STAKED");
        uint256 _stakeReward = _calculateStake(_token, msg.sender);
        ERC20Interface(_token).transfer(msg.sender, _stakeReward);
        lastStakeClaimed[_token][msg.sender] = now;
        emit StakeClaimed(now, _token, msg.sender, _stakeReward);
        return true;
    }

    // claim only rewards and restake it
    function claimRewardsOnlyAndStake(address _token) external returns (bool) {
        require(lastStakeClaimed[_token][msg.sender] != 0, "ERR_TOKEN_IS_NOT_STAKED");
        uint256 _stakeReward = _calculateStake(_token, msg.sender);

        lastStakeClaimed[_token][msg.sender] = now;
        stakeBalance[_token][msg.sender] = safeAdd(stakeBalance[_token][msg.sender], _stakeReward);
        emit StakeClaimed(now, _token, msg.sender, _stakeReward);
        emit Stake(now, _token, msg.sender, stakeBalance[_token][msg.sender]);
        return true;
    }

    // _percent should be mulitplied by 100
    function setAnnualMintPercentage(address _token, uint256 _percent) external onlyOwner() returns (bool) {
        require(listedToken[_token], "ERR_TOKEN_IS_NOT_LISTED");
        annualMintPercentage[_token] = _percent;
        return true;
    }

    // to add new token
    function addToken(address _token) external onlyOwner() {
        require(!listedToken[_token], "ERR_TOKEN_ALREADY_EXISTS");
        tokens.push(_token);
        listedToken[_token] = true;
        tokenIndex[_token] = tokens.length;
    }

    // to remove the token
    function removeToken(address _token) external onlyOwner() {
        require(listedToken[_token], "ERR_TOKEN_DOESNOT_EXISTS");
        uint256 _lastindex = tokenIndex[_token];
        address _lastaddress = tokens[safeSub(tokens.length, 1)];
        tokenIndex[_lastaddress] = _lastindex;
        tokens[_lastindex] = _lastaddress;
        tokens.pop();
        delete tokenIndex[_lastaddress];
        listedToken[_token] = false;
    }

    function availabletokens() public view returns (uint){
        return tokens.length;
    }

}
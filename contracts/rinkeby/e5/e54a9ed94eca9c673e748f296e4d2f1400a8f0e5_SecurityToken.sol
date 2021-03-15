/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

interface IERC20 {

  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  
}

interface IERC1594 {
    // Transfers
    function transferWithData(address _to, uint256 _value, bytes memory _data) external;
    function transferFromWithData(address _from, address _to, uint256 _value, bytes memory _data) external;

    // Token Issuance
    function isIssuable() external view returns (bool);
    function issue(address _tokenHolder, uint256 _value, bytes memory _data) external;

    // Token Redemption
    function redeem(uint256 _value, bytes memory _data) external;
    function redeemFrom(address _tokenHolder, uint256 _value, bytes memory _data) external;

    // Transfer Validity
    function canTransfer(address _to, uint256 _value, bytes memory _data) external view returns (bool, byte, bytes32);
    function canTransferFrom(address _from, address _to, uint256 _value, bytes memory _data) external view returns (bool, byte, bytes32);

    // Issuance / Redemption Events
    event Issued(address indexed _operator, address indexed _to, uint256 _value, bytes _data);
    event Redeemed(address indexed _operator, address indexed _from, uint256 _value, bytes _data);

}

interface IERC1644 {

    // Controller Operation
    function isControllable() external view returns (bool);
    function controllerTransfer(address _from, address _to, uint256 _value, bytes memory _data, bytes memory _operatorData) external;
    function controllerRedeem(address _tokenHolder, uint256 _value, bytes memory _data, bytes memory _operatorData) external;

    // Controller Events
    event ControllerTransfer(
        address _controller,
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    event ControllerRedemption(
        address _controller,
        address indexed _tokenHolder,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

}

library KindMath {

    /**
     * @dev Multiplies two numbers, return false on overflow.
     */
    function checkMul(uint256 a, uint256 b) internal pure returns (bool) {
        // Gas optimization: this is cheaper than requireing 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return true;
        }

        uint256 c = a * b;
        if (c / a == b)
            return true;
        else 
            return false;
    }

    /**
    * @dev Subtracts two numbers, return false on overflow (i.e. if subtrahend is greater than minuend).
    */
    function checkSub(uint256 a, uint256 b) internal pure returns (bool) {
        if (b <= a)
            return true;
        else
            return false;
    }

    /**
    * @dev Adds two numbers, return false on overflow.
    */
    function checkAdd(uint256 a, uint256 b) internal pure returns (bool) {
        uint256 c = a + b;
        if (c < a)
            return false;
        else
            return true;
    }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


contract SecurityToken is IERC20, IERC1594, IERC1644 {
    using SafeMath for uint256;

    /// @notice Name of the security token.
    string public name;

    /// @notice Symbol of the security token.
    string public symbol;

    /// @notice Decimals which will decide whether it's divisible or not and if divisible then upto how many decimal places.
    uint8 public decimals;

    /// @notice Owner of the security token.
    address public owner;

    /// @notice Maximum no. of investors allowed.
    uint256 public maxInvestors;

    /// @notice Current no. of investors.
    uint256 public investorsCount = 0;

    /// @notice List of whitelisted addresses.
    mapping (address => bool) public isWhitelisted;

    /**
    * @notice An enum representing KYC requirement of the security token
    * `NOT_REQUIRED` if KYC is not mandatory for this token
    * `REQUIRED_ONLY_FOR_ISSUANCE` if KYC is mandatory for token being issued to any investor, but token can be transferred to any investor
    * `REQUIRED_FOR_ISSUANCE_AND_TRANSFER` if KYC is mandatory for both token being issued or being transferred to any investor
    */
    enum KYCRequirement{ NOT_REQUIRED, REQUIRED_ONLY_FOR_ISSUANCE, REQUIRED_FOR_ISSUANCE_AND_TRANSFER }

    /// @notice An enum for storing KYC requirement of the security token
    KYCRequirement public kycRequirement;

    // A mapping for storing balances of investors
    mapping (address => uint256) internal _balances;

    // A mapping for storing allowances
    mapping (address => mapping (address => uint256)) internal _allowed;

    // Current total supply of token
    uint256 private _totalSupply;

    // Represents whether token is issuable
    bool internal issuance = true;

    /// @notice An event thats emitted when issuance is finalized.
    event IssuanceFinalized();

    /// @notice An event thats emitted when any address is whitelisted.
    event Whitelisted(address account);

    /**
     * @dev Gets the balance of the specified address.
     * @param _name The name of the security token.
     * @param _symbol The symbol of the security token.
     * @param _decimals The number of decimals for the security token.
     * @param _maxInvestors The maximum number of investors for the security token.
     * @param _kycRequirement The KYC requirement of the security token.
     */
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _maxInvestors, KYCRequirement _kycRequirement) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        maxInvestors = _maxInvestors;
        kycRequirement = _kycRequirement;
        owner = msg.sender;
    }

    /**
    * @return true if `msg.sender` is the owner of the contract.
    */
    function isOwner() internal view returns(bool) {
        return msg.sender == owner;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }


    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param _account The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address _account) public view override returns (uint256) {
        return _balances[_account];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return _allowed[_owner][_spender];
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _amount The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _amount) public override returns (bool) {
        require(_spender != address(0));
        _allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
     * @dev Transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _amount The amount to be transferred.
     */
    function transfer(address _to, uint256 _amount) public override returns (bool) {
        _transfer(msg.sender, _to, _amount);
        return true;
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _amount uint256 the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _amount) public override returns (bool) {
        _transferFrom(msg.sender, _from, _to, _amount);
        return true;
    }

    function _transferFrom(address _spender, address _from, address _to, uint256 _amount) internal {
        require(_amount <= _allowed[_from][_spender]);
        _allowed[_from][_spender] = _allowed[_from][_spender].sub(_amount);
        _transfer(_from, _to, _amount);
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
        require(_spender != address(0));
        _allowed[msg.sender][_spender] = (
        _allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
        require(_spender != address(0));
        _allowed[msg.sender][_spender] = (
        _allowed[msg.sender][_spender].sub(_subtractedValue));
        emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);
        return true;
    }

    /**
    * @dev Transfer token for a specified addresses
    * @param _from The address to transfer from.
    * @param _to The address to transfer to.
    * @param _amount The amount to be transferred.
    */
    function _transfer(address _from, address _to, uint256 _amount) internal {
        require(_amount <= _balances[_from]);
        require(_to != address(0));
        if(kycRequirement == KYCRequirement.REQUIRED_FOR_ISSUANCE_AND_TRANSFER)
            require(isWhitelisted[_to], "KYC Requirement failed");
        uint256 _fromNewBalance = _balances[_from].sub(_amount);
        if(balanceOf(_to) == 0 && _fromNewBalance != 0) {
            require(investorsCount < maxInvestors, "Investors limit has reached");
            investorsCount = investorsCount.add(1);
        }
        _balances[_from] = _fromNewBalance;
        _balances[_to] = _balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param _account The account that will receive the created tokens.
     * @param _amount The amount that will be created.
     */
    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(0));
        if(kycRequirement == KYCRequirement.REQUIRED_ONLY_FOR_ISSUANCE || kycRequirement == KYCRequirement.REQUIRED_FOR_ISSUANCE_AND_TRANSFER)
            require(isWhitelisted[_account], "KYC Requirement failed");
        _totalSupply = _totalSupply.add(_amount);
        if(balanceOf(_account) == 0) {
            require(investorsCount < maxInvestors, "Investors limit has reached");
            investorsCount = investorsCount.add(1);
        }
        _balances[_account] = _balances[_account].add(_amount);
        emit Transfer(address(0), _account, _amount);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param _account The account whose tokens will be burnt.
     * @param _amount The amount that will be burnt.
     */
    function _burn(address _account, uint256 _amount) internal {
        require(_account != address(0));
        require(_amount <= _balances[_account]);
        _totalSupply = _totalSupply.sub(_amount);
        _balances[_account] = _balances[_account].sub(_amount);
        if(balanceOf(_account) == 0)
            investorsCount = investorsCount.sub(1);
        emit Transfer(_account, address(0), _amount);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * @param _account The account whose tokens will be burnt.
     * @param _amount The amount that will be burnt.
     */
    function _burnFrom(address _account, uint256 _amount) internal {
        require(_amount <= _allowed[_account][msg.sender]);

        // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
        // this function needs to emit an event with the updated approval.
        _allowed[_account][msg.sender] = _allowed[_account][msg.sender].sub(_amount);
        _burn(_account, _amount);
    }

    /**
     * @notice Transfer restrictions can take many forms and typically involve on-chain rules or whitelists.
     * However for many types of approved transfers, maintaining an on-chain list of approved transfers can be
     * cumbersome and expensive. An alternative is the co-signing approach, where in addition to the token holder
     * approving a token transfer, and authorised entity provides signed data which further validates the transfer.
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @param _data The `bytes _data` allows arbitrary data to be submitted alongside the transfer.
     * for the token contract to interpret or record. This could be signed data authorising the transfer
     * (e.g. a dynamic whitelist) but is flexible enough to accomadate other use-cases.
     */
    function transferWithData(address _to, uint256 _value, bytes memory _data) external override {
        // Add a function to validate the `_data` parameter
        _transfer(msg.sender, _to, _value);
    }

    /**
     * @notice Transfer restrictions can take many forms and typically involve on-chain rules or whitelists.
     * However for many types of approved transfers, maintaining an on-chain list of approved transfers can be
     * cumbersome and expensive. An alternative is the co-signing approach, where in addition to the token holder
     * approving a token transfer, and authorised entity provides signed data which further validates the transfer.
     * @dev `msg.sender` MUST have a sufficient `allowance` set and this `allowance` must be debited by the `_value`.
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @param _data The `bytes _data` allows arbitrary data to be submitted alongside the transfer.
     * for the token contract to interpret or record. This could be signed data authorising the transfer
     * (e.g. a dynamic whitelist) but is flexible enough to accomadate other use-cases.
     */
    function transferFromWithData(address _from, address _to, uint256 _value, bytes memory _data) external override {
        // Add a function to validate the `_data` parameter
        _transferFrom(msg.sender, _from, _to, _value);
    }

    /**
     * @notice A security token issuer can specify that issuance has finished for the token
     * (i.e. no new tokens can be minted or issued).
     * @dev If a token returns FALSE for `isIssuable()` then it MUST always return FALSE in the future.
     * If a token returns FALSE for `isIssuable()` then it MUST never allow additional tokens to be issued.
     * @return bool `true` signifies the minting is allowed. While `false` denotes the end of minting
     */
    function isIssuable() external view override returns (bool) {
        return issuance;
    }

    /**
     * @notice This function must be called to increase the total supply (Corresponds to mint function of ERC20).
     * @dev It only be called by the token issuer or the operator defined by the issuer. ERC1594 doesn't have
     * have the any logic related to operator but its superset ERC1400 have the operator logic and this function
     * is allowed to call by the operator.
     * @param _tokenHolder The account that will receive the created tokens (account should be whitelisted or KYCed).
     * @param _value The amount of tokens need to be issued
     * @param _data The `bytes _data` allows arbitrary data to be submitted alongside the transfer.
     */
    function issue(address _tokenHolder, uint256 _value, bytes memory _data) external override onlyOwner {
        // Add a function to validate the `_data` parameter
        require(issuance, "Issuance has closed");
        _mint(_tokenHolder, _value);
        emit Issued(msg.sender, _tokenHolder, _value, _data);
    }

    /**
     * @notice This function redeem an amount of the token of a msg.sender. For doing so msg.sender may incentivize
     * using different ways that could be implemented with in the `redeem` function definition. But those implementations
     * are out of the scope of the ERC1594. 
     * @param _value The amount of tokens need to be redeemed
     * @param _data The `bytes _data` it can be used in the token contract to authenticate the redemption.
     */
    function redeem(uint256 _value, bytes memory _data) external override onlyOwner {
        // Add a function to validate the `_data` parameter
        _burn(msg.sender, _value);
        emit Redeemed(address(0), msg.sender, _value, _data);
    }

    /**
     * @notice This function redeem an amount of the token of a msg.sender. For doing so msg.sender may incentivize
     * using different ways that could be implemented with in the `redeem` function definition. But those implementations
     * are out of the scope of the ERC1594. 
     * @dev It is analogy to `transferFrom`
     * @param _tokenHolder The account whose tokens gets redeemed.
     * @param _value The amount of tokens need to be redeemed
     * @param _data The `bytes _data` it can be used in the token contract to authenticate the redemption.
     */
    function redeemFrom(address _tokenHolder, uint256 _value, bytes memory _data) external override onlyOwner {
        // Add a function to validate the `_data` parameter
        _burnFrom(_tokenHolder, _value);
        emit Redeemed(msg.sender, _tokenHolder, _value, _data);
    }

    /**
     * @notice Transfers of securities may fail for a number of reasons. So this function will used to understand the
     * cause of failure by getting the byte value. Which will be the ESC that follows the EIP 1066. ESC can be mapped 
     * with a reson string to understand the failure cause, table of Ethereum status code will always reside off-chain
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @param _data The `bytes _data` allows arbitrary data to be submitted alongside the transfer.
     * @return bool It signifies whether the transaction will be executed or not.
     * @return byte Ethereum status code (ESC)
     * @return bytes32 Application specific reason code 
     */
    function canTransfer(address _to, uint256 _value, bytes memory _data) external view override returns (bool, byte, bytes32) {
        // Add a function to validate the `_data` parameter
        if (_balances[msg.sender] < _value)
            return (false, 0x52, bytes32(0));

        else if (_to == address(0))
            return (false, 0x57, bytes32(0));

        else if (!KindMath.checkAdd(_balances[_to], _value))
            return (false, 0x50, bytes32(0));
        return (true, 0x51, bytes32(0));
    }

    /**
     * @notice Transfers of securities may fail for a number of reasons. So this function will used to understand the
     * cause of failure by getting the byte value. Which will be the ESC that follows the EIP 1066. ESC can be mapped 
     * with a reson string to understand the failure cause, table of Ethereum status code will always reside off-chain
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @param _data The `bytes _data` allows arbitrary data to be submitted alongside the transfer.
     * @return bool It signifies whether the transaction will be executed or not.
     * @return byte Ethereum status code (ESC)
     * @return bytes32 Application specific reason code 
     */
    function canTransferFrom(address _from, address _to, uint256 _value, bytes memory _data) external view override returns (bool, byte, bytes32) {
        // Add a function to validate the `_data` parameter
        if (_value > _allowed[_from][msg.sender])
            return (false, 0x53, bytes32(0));

        else if (_balances[_from] < _value)
            return (false, 0x52, bytes32(0));

        else if (_to == address(0))
            return (false, 0x57, bytes32(0));

        else if (!KindMath.checkAdd(_balances[_to], _value))
            return (false, 0x50, bytes32(0));
        return (true, 0x51, bytes32(0));
    }

    /// @notice A function for finalizing the issuance of token. Once finalized, token can't be issued in the future.
    function finalizeIssuance() external onlyOwner {
        require(issuance, "Issuance already closed");
        issuance = false;
        emit IssuanceFinalized();
    }

    /**
     * @notice A function for whitelisting an investor.
     * @param _account address which has to be whitelisted
     */
    function whitelist(address _account) external onlyOwner {
        require(_account != address(0), "Cannot whitelist zero address.");
        require(!isWhitelisted[_account], "Address already whitelisted.");
        isWhitelisted[_account] = true;
        emit Whitelisted(_account);
    }

    /**
     * @notice In order to provide transparency over whether `controllerTransfer` / `controllerRedeem` are useable
     * or not `isControllable` function will be used.
     * @dev If `isControllable` returns `false` then it always return `false` and
     * `controllerTransfer` / `controllerRedeem` will always revert.
     * @return bool `true` when controller address is non-zero otherwise return `false`.
     */
    function isControllable() external view override returns (bool) {
        if (owner == address(0))
            return false;
        else
            return true;
    }

    /**
     * @notice This function allows an authorised address to transfer tokens between any two token holders.
     * The transfer must still respect the balances of the token holders (so the transfer must be for at most
     * `balanceOf(_from)` tokens) and potentially also need to respect other transfer restrictions.
     * @dev This function can only be executed by the `controller` address.
     * @param _from Address The address which you want to send tokens from
     * @param _to Address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @param _data data to validate the transfer. (It is not used in this reference implementation
     * because use of `_data` parameter is implementation specific).
     * @param _operatorData data attached to the transfer by controller to emit in event. (It is more like a reason string 
     * for calling this function (aka force transfer) which provides the transparency on-chain). 
     */
    function controllerTransfer(address _from, address _to, uint256 _value, bytes memory _data, bytes memory _operatorData) external override onlyOwner {
        _transfer(_from, _to, _value);
        emit ControllerTransfer(msg.sender, _from, _to, _value, _data, _operatorData);
    }

    /**
     * @notice This function allows an authorised address to redeem tokens for any token holder.
     * The redemption must still respect the balances of the token holder (so the redemption must be for at most
     * `balanceOf(_tokenHolder)` tokens) and potentially also need to respect other transfer restrictions.
     * @dev This function can only be executed by the `controller` address.
     * @param _tokenHolder The account whose tokens will be redeemed.
     * @param _value uint256 the amount of tokens need to be redeemed.
     * @param _data data to validate the transfer. (It is not used in this reference implementation
     * because use of `_data` parameter is implementation specific).
     * @param _operatorData data attached to the transfer by controller to emit in event. (It is more like a reason string 
     * for calling this function (aka force transfer) which provides the transparency on-chain). 
     */
    function controllerRedeem(address _tokenHolder, uint256 _value, bytes memory _data, bytes memory _operatorData) external override onlyOwner {
        _burn(_tokenHolder, _value);
        emit ControllerRedemption(msg.sender, _tokenHolder, _value, _data, _operatorData);
    }

}
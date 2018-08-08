pragma solidity ^0.4.21;

// SafeMath is a part of Zeppelin Solidity library
// licensed under MIT License
// https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/LICENSE

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

// https://github.com/OpenZeppelin/zeppelin-solidity

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    /**
    * @dev Protection from short address attack
    */
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length == size + 4);
        _;
    }

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);

        _postTransferHook(msg.sender, _to, _value);

        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    /**
    * @dev Hook for custom actions to be executed after transfer has completed
    * @param _from Transferred from
    * @param _to Transferred to
    * @param _value Value transferred
    */
    function _postTransferHook(address _from, address _to, uint256 _value) internal;
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);

        _postTransferHook(_from, _to, _value);

        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract Owned {
    address owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /// @dev Contract constructor
    function Owned() public {
        owner = msg.sender;
    }
}


contract AcceptsTokens {
    ETToken public tokenContract;

    function AcceptsTokens(address _tokenContract) public {
        tokenContract = ETToken(_tokenContract);
    }

    modifier onlyTokenContract {
        require(msg.sender == address(tokenContract));
        _;
    }

    function acceptTokens(address _from, uint256 _value, uint256 param1, uint256 param2, uint256 param3) external;
}

contract ETToken is Owned, StandardToken {
    using SafeMath for uint;

    string public name = "ETH.TOWN Token";
    string public symbol = "ETIT";
    uint8 public decimals = 18;

    address public beneficiary;
    address public oracle;
    address public heroContract;
    modifier onlyOracle {
        require(msg.sender == oracle);
        _;
    }

    mapping (uint32 => address) public floorContracts;
    mapping (address => bool) public canAcceptTokens;

    mapping (address => bool) public isMinter;

    modifier onlyMinters {
        require(msg.sender == owner || isMinter[msg.sender]);
        _;
    }

    event Dividend(uint256 value);
    event Withdrawal(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    function ETToken() public {
        oracle = owner;
        beneficiary = owner;

        totalSupply_ = 0;
    }

    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
    }
    function setBeneficiary(address _beneficiary) external onlyOwner {
        beneficiary = _beneficiary;
    }
    function setHeroContract(address _heroContract) external onlyOwner {
        heroContract = _heroContract;
    }

    function _mintTokens(address _user, uint256 _amount) private {
        require(_user != 0x0);

        balances[_user] = balances[_user].add(_amount);
        totalSupply_ = totalSupply_.add(_amount);

        emit Transfer(address(this), _user, _amount);
    }

    function authorizeFloor(uint32 _index, address _floorContract) external onlyOwner {
        floorContracts[_index] = _floorContract;
    }

    function _acceptDividends(uint256 _value) internal {
        uint256 beneficiaryShare = _value / 5;
        uint256 poolShare = _value.sub(beneficiaryShare);

        beneficiary.transfer(beneficiaryShare);

        emit Dividend(poolShare);
    }

    function acceptDividends(uint256 _value, uint32 _floorIndex) external {
        require(floorContracts[_floorIndex] == msg.sender);

        _acceptDividends(_value);
    }

    function rewardTokensFloor(address _user, uint256 _tokens, uint32 _floorIndex) external {
        require(floorContracts[_floorIndex] == msg.sender);

        _mintTokens(_user, _tokens);
    }

    function rewardTokens(address _user, uint256 _tokens) external onlyMinters {
        _mintTokens(_user, _tokens);
    }

    function() payable public {
        // Intentionally left empty, for use by floors
    }

    function payoutDividends(address _user, uint256 _value) external onlyOracle {
        _user.transfer(_value);

        emit Withdrawal(_user, _value);
    }

    function accountAuth(uint256 /*_challenge*/) external {
        // Does nothing by design
    }

    function burn(uint256 _amount) external {
        require(balances[msg.sender] >= _amount);

        balances[msg.sender] = balances[msg.sender].sub(_amount);
        totalSupply_ = totalSupply_.sub(_amount);

        emit Burn(msg.sender, _amount);
    }

    function setCanAcceptTokens(address _address, bool _value) external onlyOwner {
        canAcceptTokens[_address] = _value;
    }

    function setIsMinter(address _address, bool _value) external onlyOwner {
        isMinter[_address] = _value;
    }

    function _invokeTokenRecipient(address _from, address _to, uint256 _value, uint256 _param1, uint256 _param2, uint256 _param3) internal {
        if (!canAcceptTokens[_to]) {
            return;
        }

        AcceptsTokens recipient = AcceptsTokens(_to);

        recipient.acceptTokens(_from, _value, _param1, _param2, _param3);
    }

    /**
    * @dev transfer token for a specified address and forward the parameters to token recipient if any
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @param _param1 Parameter 1 for the token recipient
    * @param _param2 Parameter 2 for the token recipient
    * @param _param3 Parameter 3 for the token recipient
    */
    function transferWithParams(address _to, uint256 _value, uint256 _param1, uint256 _param2, uint256 _param3) onlyPayloadSize(5 * 32) external returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);

        _invokeTokenRecipient(msg.sender, _to, _value, _param1, _param2, _param3);

        return true;
    }

    /**
    * @dev Hook for custom actions to be executed after transfer has completed
    * @param _from Transferred from
    * @param _to Transferred to
    * @param _value Value transferred
    */
    function _postTransferHook(address _from, address _to, uint256 _value) internal {
        _invokeTokenRecipient(_from, _to, _value, 0, 0, 0);
    }


}

contract PresaleContract is Owned {
    ETToken public tokenContract;

    /// @dev Contract constructor
    function PresaleContract(address _tokenContract) public {
        tokenContract = ETToken(_tokenContract);
    }
}


contract ETCharPresale is PresaleContract {
    using SafeMath for uint;

    bool public enabled = true;
    uint32 public maxCharId = 300;
    uint32 public currentCharId = 1;

    uint256 public currentPrice = 0.1 ether;

    mapping (uint32 => address) public owners;
    mapping (address => uint32[]) public characters;

    event Purchase(address from, uint32 charId, uint256 amount);

    function ETCharPresale(address _presaleToken)
        PresaleContract(_presaleToken)
        public
    {
    }

    function _isContract(address _user) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(_user) }
        return size > 0;
    }

    function _provideChars(address _address, uint32 _number) internal {

        for (uint32 i = 0; i < _number; i++) {
            owners[currentCharId + i] = _address;
            characters[_address].push(currentCharId + i);
            emit Purchase(_address, currentCharId + i, currentPrice);
        }

        currentCharId += _number;
        currentPrice += priceIncrease() * _number;
    }

    function priceIncrease() public view returns (uint256) {
        uint256 _currentPrice = currentPrice;

        if (_currentPrice > 0.3 ether) {
            return 0.05 finney;
        } else if (_currentPrice > 0.25 ether) {
            return 0.1 finney;
        } else if (_currentPrice > 0.2 ether) {
            return 0.2 finney;
        } else if (_currentPrice > 0.15 ether) {
            return 0.4 finney;
        } else {
            return 0.8 finney;
        }
    }

    function() public payable {
        require(enabled);
        require(!_isContract(msg.sender));

        require(msg.value >= currentPrice);

        uint32 chars = uint32(msg.value.div(currentPrice));

        require(chars <= 50);

        if (chars > 5) {
            chars = 5;
        }

        require(currentCharId + chars - 1 <= maxCharId);

        uint256 purchaseValue = currentPrice.mul(chars);
        uint256 change = msg.value.sub(purchaseValue);

        _provideChars(msg.sender, chars);

        tokenContract.rewardTokens(msg.sender, purchaseValue * 200);

        if (currentCharId > maxCharId) {
            enabled = false;
        }

        if (change > 0) {
            msg.sender.transfer(change);
        }
    }

    function setEnabled(bool _enabled) public onlyOwner {
        enabled = _enabled;
    }

    function setMaxCharId(uint32 _maxCharId) public onlyOwner {
        maxCharId = _maxCharId;
    }

    function setCurrentPrice(uint256 _currentPrice) public onlyOwner {
        currentPrice = _currentPrice;
    }

    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    function charactersOf(address _user) public view returns (uint32[]) {
        return characters[_user];
    }
}
pragma solidity ^0.4.24;

contract ERC20Basic {
    function balanceOf(address _who) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

/**
 * Identity contract containing funds and accessors (ethereum public keys or contract addresses)
 * It can hold eth and any ERC20 token
 * The goal is to be able to give various permissions to your own keys
 * or to contracts similar to ZincAccessor by providing a fixed interface
 */

contract Identity {

    enum Purposes {
        NONE,             // 0b0000
        READ_ONLY,        // 0b0001
        WRITE_ONLY,       // 0b0010
        ___,
        KEY_MANAGEMENT,   // 0b0100
        _____,
        ______,
        _______,
        FUNDS_MANAGEMENT, // 0b1000
        _________,
        __________,
        ___________,
        ____________,
        _____________,
        ______________,
        ALL_PURPOSES      // 0b1111
    }

    event AccessorAdded(address indexed key, uint8 indexed purpose);
    event AccessorRemoved(address indexed key, uint8 indexed purpose);
    event AccessorUpdated(address indexed key, uint8 indexed oldPurpose, uint8 indexed newPurpose);

    mapping(address => uint8) accessorMap;

    /**
    * Constructs an Identity contract
    * @param _initialAccessors The initial accessors array
    * @param _purposes The initial purposes for each accessor
    * Emits AccessorAdded for each accessor
    */
    constructor(address[] _initialAccessors, uint8[] _purposes) public {
        uint arrayLength = _initialAccessors.length;
        require(arrayLength == _purposes.length, "Arrays must be of the same size");
        for(uint i = 0; i < arrayLength; i++) {
            accessorMap[_initialAccessors[i]] = _purposes[i];
            emit AccessorAdded(_initialAccessors[i], _purposes[i]);
        }
    }

    modifier allowedByPurpose(Purposes _purpose) {
        require(accessorMap[msg.sender] & uint8(_purpose) != 0, "Not authorized");
        _;
    }

    modifier checkPurpose(uint8 _purpose) {
        require(_purpose > uint8(Purposes.NONE) && _purpose <= uint8(Purposes.ALL_PURPOSES), "Invalid purpose");
        _;
    }

    /**
     * Returns the purpose for an accessor, 0 if accessor isn&#39;t registered
     */
    function getAccessorPurpose(address _key) public view returns(uint8) {
        return accessorMap[_key];
    }

    /**
     * Adds an accessor with purpose
     * @param _key Eth public key or contract address
     * @param _purpose Purpose for accessor
     * Requires KEY_MANAGEMENT purpose for msg.sender
     * Emits AccessorUpdated or AccessorAdded
     */
    function addAccessor(address _key, uint8 _purpose) public allowedByPurpose(Purposes.KEY_MANAGEMENT) checkPurpose(_purpose) {
        uint8 oldPurpose = accessorMap[_key];
        accessorMap[_key] = _purpose;
        if (oldPurpose != 0) {
            emit AccessorUpdated(_key, oldPurpose, _purpose);
        } else {
            emit AccessorAdded(_key, _purpose);
        }
    }

    /**
     * Remove an accessor
     * @param _key Eth public key or contract address
     * Requires KEY_MANAGEMENT purpose for msg.sender
     * Emits AccessorRemoved
     */
    function removeAccessor(address _key) public allowedByPurpose(Purposes.KEY_MANAGEMENT) {
        uint8 purpose = accessorMap[_key];
        delete accessorMap[_key];
        emit AccessorRemoved(_key, purpose);
    }

    /**
     * Send all ether to msg.sender
     * Requires FUNDS_MANAGEMENT purpose for msg.sender
     */
    function withdraw() public allowedByPurpose(Purposes.FUNDS_MANAGEMENT) {
        msg.sender.transfer(address(this).balance);
    }

    /**
     * Transfer ether to _account
     * @param _amount amount to transfer in wei
     * @param _account recepient
     * Requires FUNDS_MANAGEMENT purpose for msg.sender
     */
    function transferEth(uint _amount, address _account) allowedByPurpose(Purposes.FUNDS_MANAGEMENT) public {
        require(_amount <= address(this).balance, "Amount should be less than total balance of the contract");
        require(_account != address(0), "must be valid address");
        _account.transfer(_amount);
    }

    /**
     * Returns contract eth balance
     */
    function getBalance() public view returns(uint)  {
        return address(this).balance;
    }

    /**
     * Returns ERC20 token balance for _token
     * @param _token token address
     */
    function getTokenBalance(address _token) public view returns (uint) {
        return ERC20Basic(_token).balanceOf(this);
    }

    /**
     * Send all tokens for _token to msg.sender
     * @param _token ERC20 contract address
     * Requires FUNDS_MANAGEMENT purpose for msg.sender
     */
    function withdrawTokens(address _token) public allowedByPurpose(Purposes.FUNDS_MANAGEMENT) {
        require(_token != address(0));
        ERC20Basic token = ERC20Basic(_token);
        uint balance = token.balanceOf(this);
        // token returns true on successful transfer
        assert(token.transfer(msg.sender, balance));
    }

    /**
     * Send tokens for _token to _to
     * @param _token ERC20 contract address
     * @param _to recepient
     * @param _amount amount in 
     * Requires FUNDS_MANAGEMENT purpose for msg.sender
     */
    function transferTokens(address _token, address _to, uint _amount) public allowedByPurpose(Purposes.FUNDS_MANAGEMENT) {
        require(_token != address(0));
        require(_to != address(0));
        ERC20Basic token = ERC20Basic(_token);
        uint balance = token.balanceOf(this);
        require(_amount <= balance);
        assert(token.transfer(_to, _amount));
    }

    function () public payable {}
}
/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

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


pragma solidity 0.8.7;

interface IKommunitasGov{
    event RegistrationCreated(address indexed registration, uint index);
    
    function owner() external  view returns (address);
    function komv() external  view returns (address);
    
    function allRegistrationsLength() external view returns(uint);
    function allRegistrations(uint) external view returns(address);

    function createRegistration(string memory, string memory) external returns (address);
    
    function transferOwnership(address) external;
}


pragma solidity 0.8.7;

interface IKommunitasProject{
    function migrateCandidate(address[] memory) external returns (bool);
}


pragma solidity 0.8.7;

contract Registration{
    bytes32 public DOMAIN_SEPARATOR;

    IKommunitasGov public gov;
    address[] public candidate;
    bool public initialized;

    struct Form {
        address from;
        string content;
    }

    bytes32 constant FORM_TYPEHASH = keccak256(
        "Form(address from,string content)"
    );

    modifier onlyGov {
        require(msg.sender == address(gov), "Not gov");
        _;
    }

    modifier onlyOperator {
        require(msg.sender == gov.owner(), "Not operator");
        _;
    }

    constructor() {
        gov = IKommunitasGov(msg.sender);
    }

    function getCandidateLength() external view returns (uint) {
        return candidate.length;
    }

    function initialize(string memory name, string memory version) external onlyGov {
        require(!initialized, "Initialized");

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR =  keccak256(abi.encode(
            // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
            0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            chainId,
            address(this)
        ));

        initialized = true;
    }

    function hash(Form memory form) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            FORM_TYPEHASH,
            form.from,
            keccak256(bytes(form.content))
        ));
    }

    // TESTING
    function show(address _from, bytes memory _signature) public view returns(address) {
        if(_signature.length != 65) return address(0);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        Form memory form = Form({
            from: _from,
            content: "I want to join on booster 1 project"
        });

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            hash(form)
        ));

        return ecrecover(digest, v, r, s);
    }

    function verify(address _from, bytes memory _signature) public view returns (bool) { // TESTING !
    // function verify(address _from, string memory _content, _signature) internal view returns(bool) {
        if(_signature.length != 65) return false;

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        Form memory form = Form({
            from: _from,
            content: "I want to join on booster 1 project"
        });

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            hash(form)
        ));

        return ecrecover(digest, v, r, s) == _from;
    }

    function migrate(address _saleTarget, address[] memory _from, bytes[] memory _signature) external onlyOperator {
        require(_saleTarget != address(0), "address(0) detected");
        require(_from.length == _signature.length, "length missmatch");

        for(uint i=0; i<_from.length; i++){
            if(!verify(_from[i], _signature[i]) && IERC20(gov.komv()).balanceOf(_from[i]) == 0) continue;

            candidate.push(_from[i]);
        }

        require(IKommunitasProject(_saleTarget).migrateCandidate(candidate));
    }
}


pragma solidity 0.8.7;

contract KommunitasGov is IKommunitasGov{
    address[] public override allRegistrations; // all registrations created
    
    address public override owner;
    address public override immutable komv;

    modifier onlyOwner{
        require(owner == msg.sender, "Not owner");
        _;
    }
    
    constructor(address _komv){
        require(_komv != address(0), "address(0) detected");
        
        owner = msg.sender;
        komv = _komv;
    }
    
    /**
     * @dev Get total number of registrations created
     */
    function allRegistrationsLength() public override view returns (uint) {
        return allRegistrations.length;
    }
    
    /**
     * @dev Create new registration
     * @param _name Project name
     * @param _version Project registration version
     */
    function createRegistration(string memory _name, string memory _version) public override onlyOwner returns(address registration){
        require(bytes(_name).length != 0 && bytes(_version).length != 0, "Name & version empty");
        
        registration = address(new Registration());

        allRegistrations.push(registration);
        
        Registration(allRegistrations[allRegistrations.length-1]).initialize(_name, _version);
        
        emit RegistrationCreated(registration, allRegistrations.length-1);
    }
    
    /**
     * @dev Transfer ownership to new owner
     * @param _newOwner New owner
     */
    function transferOwnership(address _newOwner) public override onlyOwner{
        require(_newOwner != address(0), "Can't set to address(0)");
        owner = _newOwner;
    }

}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./common/EIP712MetaTransaction.sol";

contract CardToken is EIP712MetaTransaction {

    string private _name = "DUNO CARD";
    string private _symbol = "CARD";
    uint8 private _decimals = 18;

    address public CardMaster;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    modifier onlyCardMaster {
        require(
            _msgSender() == CardMaster,
            'CardToken: access denied'
        );
        _;
    }

    constructor(
        address _CardMaster
    )
    EIP712Base('CardToken', 'v1.2')
    {
        CardMaster = _CardMaster;
    }

    function transferOwnership(
        address _contractDAO
    )
    external
    onlyCardMaster
    {
        CardMaster = _contractDAO;
    }

    function renounceOwnership()
    external
    onlyCardMaster
    {
        CardMaster = address(0x0);
    }

    function name()
    external
    view
    returns (string memory)
    {
        return _name;
    }

    function symbol()
    external
    view
    returns (string memory)
    {
        return _symbol;
    }

    function decimals()
    external
    view
    returns (uint8)
    {
        return _decimals;
    }

    function totalSupply()
    external
    view
    returns (uint256)
    {
        return _totalSupply;
    }

    function balanceOf(
        address _account
    )
    external
    view
    returns (uint256)
    {
        return _balances[_account];
    }

    function transfer(
        address _recipient,
        uint256 _amount
    )
    external
    returns (bool)
    {
        _transfer(
            _msgSender(),
            _recipient,
            _amount
        );

        return true;
    }

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    )
    internal
    {
        _balances[_sender] =
        _balances[_sender] - _amount;

        _balances[_recipient] =
        _balances[_recipient] + _amount;

        emit Transfer(
            _sender,
            _recipient,
            _amount
        );
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    )
    external
    returns (bool)
    {
        _approve(
            _sender,
            _msgSender(),
            _allowances[_sender][_msgSender()] - _amount
        );

        _transfer(
            _sender,
            _recipient,
            _amount
        );

        return true;
    }

    function allowance(
        address _owner,
        address _spender
    )
    external
    view
    returns (uint256)
    {
        return _allowances[_owner][_spender];
    }

    function approve(
        address _spender,
        uint256 _amount
    )
    external
    returns (bool)
    {
        _approve(
            _msgSender(),
            _spender,
            _amount
        );

        return true;
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    )
    internal
    {
        _allowances[_owner][_spender] = _amount;

        emit Approval(
            _owner,
            _spender,
            _amount
        );
    }

    function mint(
        address _account,
        uint256 _amount
    )
    external
    onlyCardMaster
    {
        _totalSupply =
        _totalSupply + _amount;

        _balances[_account] =
        _balances[_account] + _amount;

        emit Transfer(
            address(0x0),
            _account,
            _amount
        );
    }

    function burn(
        uint256 _amount
    )
    external
    {
        _balances[_msgSender()] =
        _balances[_msgSender()] - _amount;

        _totalSupply =
        _totalSupply - _amount;

        emit Transfer(
            _msgSender(),
            address(0x0),
            _amount
        );
    }

    function _msgSender()
    internal
    view
    returns (address sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
            // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                mload(add(array, index)),
                0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./EIP712Base.sol";

abstract contract EIP712MetaTransaction is EIP712Base {

    bytes32 private constant META_TRANSACTION_TYPEHASH =
    keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );

    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );

    mapping(address => uint256) internal nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    public
    payable
    returns(bytes memory)
    {
        MetaTransaction memory metaTx = MetaTransaction(
        {
        nonce: nonces[userAddress],
        from: userAddress,
        functionSignature: functionSignature
        }
        );

        require(
            verify(
                userAddress,
                metaTx,
                sigR,
                sigS,
                sigV
            ), "Signer and signature do not match"
        );

        nonces[userAddress] =
        nonces[userAddress] + 1;

        // Append userAddress at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(
                functionSignature,
                userAddress
            )
        );

        require(
            success,
            'Function call not successful'
        );

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        return returnData;
    }

    function hashMetaTransaction(
        MetaTransaction memory metaTx
    )
    internal
    pure
    returns (bytes32)
    {
        return keccak256(
            abi.encode(
                META_TRANSACTION_TYPEHASH,
                metaTx.nonce,
                metaTx.from,
                keccak256(metaTx.functionSignature)
            )
        );
    }

    function verify(
        address user,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    internal
    view
    returns (bool)
    {
        address signer = ecrecover(
            toTypedMessageHash(
                hashMetaTransaction(metaTx)
            ),
            sigV,
            sigR,
            sigS
        );

        require(
            signer != address(0x0),
            'Invalid signature'
        );
        return signer == user;
    }

    function msgSender() internal view returns(address sender) {
        if(msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
            // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }

    function getNonce(
        address _user
    )
    external
    view
    returns(uint256 nonce)
    {
        nonce = nonces[_user];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract EIP712Base {

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"));
    bytes32 internal domainSeperator;

    constructor(string memory name, string memory version) {
        domainSeperator = keccak256(abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                getChainID(),
                address(this)
            ));
    }

    function getChainID() internal pure returns (uint256 id) {
        assembly {
            id := 1 // set to Goerli for now, Mainnet later
        }
    }

    function getDomainSeperator() private view returns(bytes32) {
        return domainSeperator;
    }

    /**
    * Accept message hash and returns hash message in EIP712 compatible form
    * So that it can be used to recover signer from signature signed using EIP712 formatted data
    * https://eips.ethereum.org/EIPS/eip-712
    * "\\x19" makes the encoding deterministic
    * "\\x01" is the version byte to make it compatible to EIP-191
    */
    function toTypedMessageHash(bytes32 messageHash) internal view returns(bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash));
    }
}
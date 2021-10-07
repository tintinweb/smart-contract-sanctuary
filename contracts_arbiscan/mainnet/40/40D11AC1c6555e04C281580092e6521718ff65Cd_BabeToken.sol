/**
 *Submitted for verification at arbiscan.io on 2021-09-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract BabeToken {
    string public constant name = "WenWaifu";
    string public constant symbol = "BABE";
    uint256 public constant decimals = 18;
    uint256 public immutable totalSupply;
    address immutable sushiRouter;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    bytes32 public immutable DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    constructor(uint256 _totalSupply, address _sushiRouter) {
        sushiRouter = _sushiRouter;
        totalSupply = _totalSupply;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256)
    {
        if (_spender == sushiRouter) {
            return type(uint256).max;
        }
        return allowed[_owner][_spender];
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "NYAN: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "BABE: INVALID_SIGNATURE"
        );

        allowed[owner][spender] = value;

        emit Approval(owner, spender, value);
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(balances[_from] >= _value, "Insufficient balance");

        unchecked {
            balances[_from] -= _value;
            balances[_to] = balances[_to] + _value;
        }

        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool) {
        if (msg.sender != sushiRouter) {
            require(
                allowed[_from][msg.sender] >= _value,
                "Insufficient allowance"
            );
            unchecked {
                allowed[_from][msg.sender] =
                    allowed[_from][msg.sender] -
                    _value;
            }
        }
        _transfer(_from, _to, _value);
        return true;
    }
}
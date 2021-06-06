/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;



// File: FUCKRUG.sol

// This contract was created to fuck all the carpets and rugs
// Stop buying the shitcoins listed here everyday
// This contract is a meme, it is worthless
// What to expect from it?
// - You are not going to get rugged
// - Deployer of the contract received 1% of the total supply to provide liquidity to Uniswap
// - Ownership of the contract was renounced after the above. No more owner minting can happen
// - On each transfer 3 things are checked:
//   a. gas is non-zero, to avoid Flashbots having fun with you here
//   b. the transfer amount is limited to 696 FUCKRUGs, to fuck (to a degree) liquidity snipers and bots
//   c. ensures that the transfer amount is larger than 0.69 FUCKRUG to (i) !moon (ii) teach people to give
// - On each transfer the address that previously transferred, shall receive a tip of 0.69
// - Total Circulating Supply of the token goes up only if people transact in the token (the above tip)
// - Total Supply of the token is capped at 696969 tokens
contract FUCKRUG {
    address public owner;
    address private prev;
    uint256 public holyGrail = 696e18;
    uint256 public holyShit = 69e17;
    uint256 public holyGas = 69e8;
    uint8 public constant decimals = 18;
    string public name;
    string public symbol;
    string public constant version = "1";

    uint256 public totalCirculatingSupply = 0;
    uint256 public totalSupply = 696969e18;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    // aka stackOf
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Approval(address indexed src, address indexed usr, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);

    constructor() {
        symbol = "FUCKRUG";
        name = "FUCK ALL RUGS";

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );

        owner = msg.sender;
    }

    function renounceOwnership() external {
        require(msg.sender == owner, "FUCKRUG::renounceOwnership: fu");
        owner = address(0);
    }

    function transfer(address dst, uint256 wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public virtual returns (bool) {
        require(holyGrail > wad, "FUCKRUG::transferFrom: fuck snipers");
        require(holyGas < tx.gasprice, "FUCKRUG::transferFrom: fuck bots");
        require(
            wad > holyShit,
            "FUCKRUG::transferFrom: give and you shall receive"
        );
        require(
            balanceOf[src] >= wad,
            "FUCKRUG::transferFrom: insufficient-balance"
        );
        if (
            src != msg.sender && allowance[src][msg.sender] != type(uint256).max
        ) {
            require(
                allowance[src][msg.sender] >= wad,
                "FUCKRUG::transferFrom: insufficient-allowance"
            );
            allowance[src][msg.sender] = allowance[src][msg.sender] - wad;
        }
        // fuck ruggers get divis, like in boomer corpos
        if (prev != address(0)) {
            if (totalCirculatingSupply < totalSupply) {
                totalCirculatingSupply = totalCirculatingSupply + holyShit;
                balanceOf[prev] = balanceOf[prev] + holyShit;
            }
        }
        balanceOf[src] = balanceOf[src] - wad;
        balanceOf[dst] = balanceOf[dst] + wad;
        prev = msg.sender;
        emit Transfer(src, dst, wad);
        return true;
    }

    // to be able to supply the initial fucking liquidity to uniswap
    function mint(address usr, uint256 wad) external virtual {
        require(msg.sender == owner, "FUCKRUG::mint: one fuckrugger only");
        balanceOf[usr] = balanceOf[usr] + wad;
        totalCirculatingSupply = totalCirculatingSupply + wad;
        emit Transfer(address(0), usr, wad);
    }

    function burn(address usr, uint256 wad) public {
        require(balanceOf[usr] >= wad, "FUCKRUG::burn: insufficient-balance");
        if (
            usr != msg.sender && allowance[usr][msg.sender] != type(uint256).max
        ) {
            require(
                allowance[usr][msg.sender] >= wad,
                "FUCKRUG::burn: insufficient-allowance"
            );
            allowance[usr][msg.sender] = allowance[usr][msg.sender] - wad;
        }
        balanceOf[usr] = balanceOf[usr] - wad;
        totalCirculatingSupply = totalCirculatingSupply - wad;
        emit Transfer(usr, address(0), wad);
    }

    function approve(address usr, uint256 wad) external returns (bool) {
        allowance[msg.sender][usr] = wad;
        emit Approval(msg.sender, usr, wad);
        return true;
    }

    function burnFrom(address usr, uint256 wad) external {
        burn(usr, wad);
    }

    function stackOf(address usr) external view returns (uint256) {
        return balanceOf[usr];
    }

    function permit(
        address _owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "FUCKRUG::permit: past-deadline");
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            _owner,
                            spender,
                            value,
                            nonces[_owner]++,
                            deadline
                        )
                    )
                )
            );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == _owner,
            "FUCKRUG::permit: invalid-sig"
        );
        allowance[_owner][spender] = value;
        emit Approval(_owner, spender, value);
    }
}
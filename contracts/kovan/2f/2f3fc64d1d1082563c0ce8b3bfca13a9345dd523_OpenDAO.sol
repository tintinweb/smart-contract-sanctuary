// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";

contract OpenDAO is ERC20, EIP712 {
    uint256 public constant MAX_SUPPLY = uint248(1e14 ether);

    // for DAO.
    uint256 public constant AMOUNT_DAO = MAX_SUPPLY / 100 * 20;
    address public constant ADDR_DAO = 0x06bB1467b38d726b3eb39eB2FBAE6021feAE935F;

    // for staking
    uint256 public constant AMOUNT_STAKING = MAX_SUPPLY / 100 * 20;
    address public constant ADDR_STAKING = 0x7d28988391034A4C756f0c3E1A3E033175B04C77;

    // for liquidity providers
    uint256 public constant AMOUNT_LP = MAX_SUPPLY / 100 * 10;
    address public constant ADDR_LP = 0x709CD2aAAe592930616720115b6a3Dbdf1407664;

    // for airdrop
    uint256 public constant AMOUNT_AIREDROP = MAX_SUPPLY - (AMOUNT_DAO + AMOUNT_STAKING + AMOUNT_LP);

    constructor(string memory _name, string memory _symbol, address _signer) ERC20(_name, _symbol) EIP712("OpenDAO", "1") {
        _mint(ADDR_DAO, AMOUNT_DAO);
        _mint(ADDR_STAKING, AMOUNT_STAKING);
        _mint(ADDR_LP, AMOUNT_LP);
        _totalSupply = AMOUNT_DAO + AMOUNT_STAKING + AMOUNT_LP;
        cSigner = _signer;
    }

    bytes32 constant public MINT_CALL_HASH_TYPE = keccak256("mint(address receiver,uint256 amount)");

    address public immutable cSigner;

    function claim(uint256 amountV, bytes32 r, bytes32 s) external {
        uint256 amount = uint248(amountV);
        uint8 v = uint8(amountV >> 248);
        uint256 total = _totalSupply + amount;
        require(total <= MAX_SUPPLY, "OpenDAO: Exceed max supply");
        require(minted(msg.sender) == 0, "OpenDAO: Claimed");
        bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", 
            ECDSA.toTypedDataHash(_domainSeparatorV4(),
                keccak256(abi.encode(MINT_CALL_HASH_TYPE, msg.sender, amount))
        )));
        require(ecrecover(digest, v, r, s) == cSigner, "OpenDAO: Invalid signer");
        _totalSupply = total;
        _mint(msg.sender, amount);
    }
}
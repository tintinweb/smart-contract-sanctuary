// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Math.sol";
import "./EIP712.sol";
import "./ECDSA.sol";

contract GroupDAO is ERC20, EIP712 {
    uint256 public constant MAX_SUPPLY = uint248(1e14 ether);

    // 1 month
    uint256 public constant LOCK_TIME = 2592000;
    uint256 public constant END_AIRDROP = 1643644800;

    // for DAO
    uint256 public constant AMOUNT_DAO = MAX_SUPPLY / 100 * 20;
    address public constant ADDR_DAO = 0x58E5a5df8eF5EbEbe9FF2943cE45f79E7511e2d7;

    // for team, lock 5 year, unlock 1/60 per month
    uint256 public constant AMOUNT_STAKING = MAX_SUPPLY / 100 * 20;
    address public constant ADDR_STAKING = 0xEF0E03599a3a4a72A1be22A1dFAdCe2005681eaF;
    uint256 public constant AMOUNT_UNLOCKED_MONTH = AMOUNT_STAKING / 60;

    // for liquidity providers
    uint256 public constant AMOUNT_LP = MAX_SUPPLY / 100 * 9;
    address public constant ADDR_LP = 0xfE287b54288189bd492ee5c39A4114001Ace1bAa;

    // for init liquidity providers
    uint256 public constant AMOUNT_ILP = MAX_SUPPLY / 100 * 1;
    address public constant ADDR_ILP = 0x51c0037aeEdAE7B046D539eeFf3FFa1B9232a0b6;

    // for airdrop
    uint256 public constant AMOUNT_AIRDROP = MAX_SUPPLY - (AMOUNT_DAO + AMOUNT_STAKING + AMOUNT_LP + AMOUNT_ILP);

    uint256 public START_TIME = 0;
    bytes32 constant public MINT_CALL_HASH_TYPE = keccak256("mint(address receiver,uint256 amount)");
    address public immutable cSigner;

    constructor(string memory _name, string memory _symbol, address _signer) ERC20(_name, _symbol) EIP712("GroupDAO", "1") {
        _mint(ADDR_DAO, AMOUNT_DAO);
        _mint(ADDR_STAKING, AMOUNT_STAKING);
        _mint(ADDR_LP, AMOUNT_LP);
        _mint(ADDR_ILP, AMOUNT_ILP);
        _totalSupply = AMOUNT_DAO + AMOUNT_STAKING + AMOUNT_LP + AMOUNT_ILP;
        cSigner = _signer;
        START_TIME = block.timestamp;
    }


    function claim(uint256 amountV, bytes32 r, bytes32 s) external {
        require(block.timestamp < END_AIRDROP, "GroupDAO: AirDrop Finished");

        uint256 amount = uint248(amountV);
        uint8 v = uint8(amountV >> 248);
        uint256 total = _totalSupply + amount;
        require(total <= MAX_SUPPLY, "GroupDAO: Exceed max supply");
        require(minted(msg.sender) == 0, "GroupDAO: Claimed");
        bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",
                ECDSA.toTypedDataHash(_domainSeparatorV4(),
                keccak256(abi.encode(MINT_CALL_HASH_TYPE, msg.sender, amount))
        )));
        require(ecrecover(digest, v, r, s) == cSigner, "GroupDAO: Invalid signer");
        _totalSupply = total;
        _mint(msg.sender, amount);

    }

    function _checkSenderLock(uint256 amount) internal override view{
        if(msg.sender == ADDR_STAKING){
            uint256 passed = Math.div(block.timestamp - START_TIME, LOCK_TIME);
            if(passed <= 60){
                uint256 locked_amount = AMOUNT_UNLOCKED_MONTH * (60 - passed);
                uint256 least_amount = locked_amount + amount;
                require(balanceOf(ADDR_STAKING) >= least_amount, "GroupDAO: Transfer Locked");
            }
        }
        if(msg.sender == ADDR_DAO || msg.sender == ADDR_LP){
                require(block.timestamp > END_AIRDROP, "GroupDAO: Transfer Locked");
        }
    }
}
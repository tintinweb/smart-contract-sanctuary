// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Math.sol";
import "./EIP712.sol";
import "./ECDSA.sol";

contract DisDAO is ERC20, EIP712 {
    uint256 public constant MAX_SUPPLY = uint248(1e14 ether);

    // 30 days
    uint256 public constant LOCK_TIME = 2592000;
    uint256 public constant END_AIRDROP = 1646092800;

    // for DAO
    uint256 public constant AMOUNT_DAO = MAX_SUPPLY / 100 * 25;
    address public constant ADDR_DAO = 0xE450fe0f9DeAad5B1cB8fC691d95Ce1f723e0ced;

    // for team, lock 2.5 year, unlock 1/30 per month
    uint256 public constant AMOUNT_STAKING = MAX_SUPPLY / 100 * 10;
    address public constant ADDR_STAKING = 0x1fF3A2Bf533ABd1F863B5aE5f601554068A5818F;
    uint256 public constant AMOUNT_UNLOCKED_MONTH = AMOUNT_STAKING / 30;

    // for liquidity providers
    uint256 public constant AMOUNT_LP = MAX_SUPPLY / 100 * 14;
    address public constant ADDR_LP = 0x5bC4e9F6fEeE3D381803AD70849F5928262d3C66;

    // for init liquidity providers
    uint256 public constant AMOUNT_ILP = MAX_SUPPLY / 100 * 1;
    address public constant ADDR_ILP = 0xb1A77965B8DAe65E21001E528043A21607265be1;

    // for airdrop
    uint256 public constant AMOUNT_AIRDROP = MAX_SUPPLY - (AMOUNT_DAO + AMOUNT_STAKING + AMOUNT_LP + AMOUNT_ILP);

    uint256 public START_TIME = 0;
    string constant public APPROVE_MSG = "approve(address account, uint256 amount)";
    address public immutable signer;

    constructor(string memory _name, string memory _symbol, address _signer) ERC20(_name, _symbol) EIP712("DisDAO", "1.0") {
        _mint(ADDR_DAO, AMOUNT_DAO);
        _mint(ADDR_STAKING, AMOUNT_STAKING);
        _mint(ADDR_LP, AMOUNT_LP);
        _mint(ADDR_ILP, AMOUNT_ILP);
        _totalSupply = AMOUNT_DAO + AMOUNT_STAKING + AMOUNT_LP + AMOUNT_ILP;
        signer = _signer;
        START_TIME = block.timestamp;
    }


    function claim(uint256 amount, uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp < END_AIRDROP, "AirDrop Expired");
        uint256 total = _totalSupply + amount;
        require(total <= MAX_SUPPLY, "Exceed maximum supply");
        require(minted(msg.sender) == 0, "Already Claimed");
        bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",
                                   keccak256(abi.encode(APPROVE_MSG, msg.sender, amount))));
        require(ecrecover(digest, v, r, s) == signer, "Invalid signer");
        _totalSupply = total;
        _mint(msg.sender, amount);

    }

    function _checkSenderLock(uint256 amount) internal override view {
        if(msg.sender == ADDR_STAKING){
            uint256 passed = Math.div(block.timestamp - START_TIME, LOCK_TIME);
            if(passed <= 60){
                uint256 locked_amount = AMOUNT_UNLOCKED_MONTH * (30 - passed);
                uint256 least_amount = locked_amount + amount;
                require(balanceOf(ADDR_STAKING) >= least_amount, "Transfer Locked");
            }
        }
        if(msg.sender == ADDR_DAO || msg.sender == ADDR_LP){
                require(block.timestamp > END_AIRDROP, "Transfer Locked");
        }
    }
}
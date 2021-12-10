pragma solidity ^0.5.0;

import './SafeMath.sol';
import './IGenArt721Minter_DoodleLabs_Config.sol';
import './IGenArt721CoreV2.sol';

contract GenArt721Minter_DoodleLabs_Config is IGenArt721Minter_DoodleLabs_Config {
    using SafeMath for uint256;

    event SetState(uint256 projectId, uint256 state);
    event SetPurchaseManyLimit(uint256 projectId, uint256 limit);

    enum SaleState {
        FAMILY_COLLECTORS,
        REDEMPTION,
        PUBLIC
    }

    IGenArt721CoreV2 public genArtCoreContract;

    mapping(uint256 => SaleState) public state;
    mapping(uint256 => uint256) public purchaseLimit;

    modifier onlyWhitelisted() {
        require(genArtCoreContract.isWhitelisted(msg.sender), "can only be set by admin");
        _;
    }

    constructor(address _genArt721Address) public {
        genArtCoreContract = IGenArt721CoreV2(_genArt721Address);
    }

    function getPurchaseManyLimit(uint256 projectId) public returns (uint256 limit) {
        return purchaseLimit[projectId];
    }

    function getState(uint256 projectId) public returns (uint256 _state) {
        return uint256(state[projectId]);
    }

    function setStateFamilyCollectors(uint256 projectId) public onlyWhitelisted {
        state[projectId] = SaleState.FAMILY_COLLECTORS;
        emit SetState(projectId, uint256(state[projectId]));
    }

    function setStateRedemption(uint256 projectId) public onlyWhitelisted {
        state[projectId] = SaleState.REDEMPTION;
        emit SetState(projectId, uint256(state[projectId]));
    }

    function setStatePublic(uint256 projectId) public onlyWhitelisted {
       state[projectId] = SaleState.PUBLIC;
       emit SetState(projectId, uint256(state[projectId]));
    }

    function setPurchaseManyLimit(uint256 projectId, uint256 limit) public onlyWhitelisted {
        purchaseLimit[projectId] = limit;
        emit SetPurchaseManyLimit(projectId, limit);
    }
}
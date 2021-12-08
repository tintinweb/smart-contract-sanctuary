pragma solidity ^0.5.0;

import './SafeMath.sol';
import './IGenArtMinterV2_State.sol';
import './IGenArt721CoreV2.sol';

contract GenArtMinterV2_State is IGenArtMinterV2_State {
    using SafeMath for uint256;

    event SetState(uint256 projectId, uint256 state);

    enum SaleState {
        FAMILY_COLLECTORS,
        REDEMPTION,
        PUBLIC
    }

    IGenArt721CoreV2 public genArtCoreContract;

    mapping(uint256 => SaleState) public state;

    modifier onlyWhitelisted() {
        require(genArtCoreContract.isWhitelisted(msg.sender), "can only be set by admin");
        _;
    }

    constructor(address _genArt721Address) public {
        genArtCoreContract = IGenArt721CoreV2(_genArt721Address);
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
}
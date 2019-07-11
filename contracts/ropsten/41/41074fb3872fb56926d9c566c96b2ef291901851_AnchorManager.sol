/**
 *Submitted for verification at Etherscan.io on 2019-07-08
*/

// File: contracts/Interfaces.sol

pragma solidity 0.5.10;


interface ERC20Interface {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);

    function totalSupply() external view returns(uint256 supply);
    function balanceOf(address _owner) external view returns(uint256 balance);
    //solhint-disable-next-line no-simple-event-func-name
    function transfer(address _to, uint256 _value) external returns(bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns(bool success);
    function approve(address _spender, uint256 _value) external returns(bool success);
    function allowance(address _owner, address _spender) external view returns(uint256 remaining);

    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function name() external view returns(string memory);
}

interface EToken2Interface {
    function reissueAsset(bytes32 _symbol, uint _value) external returns(bool);
    function revokeAsset(bytes32 _symbol, uint _value) external returns(bool);
}

interface AssetProxyInterface {
    function etoken2Symbol() external view returns(bytes32);
    function etoken2() external view returns(EToken2Interface);
}

interface AnchorPhaseInterface {
    function anct() external view returns(ERC20Interface);
    function doct() external view returns(ERC20Interface);
    function ANCT() external view returns(bytes32);
    function DOCT() external view returns(bytes32);
    function eToken2() external view returns(EToken2Interface);
}

contract AnchorManagerInterface {
    function executeContraction(uint _doctValue) external;
    function executeExpansion(uint _anctValue) external;
    function execute(address _to, bytes calldata _data) external;
}

// File: contracts/AnchorManager.sol

pragma solidity 0.5.10;
pragma experimental ABIEncoderV2;



contract AnchorManager is AnchorManagerInterface {
    address public anchorVotes;
    AnchorPhaseInterface public anchorPhase;

    constructor (address _anchorVotes, AnchorPhaseInterface _anchorPhase) public
    {
        anchorVotes = _anchorVotes;
        anchorPhase = _anchorPhase;
    }

    function executeContraction(uint _doctValue) public {
        require(msg.sender == anchorVotes, &#39;Access denied&#39;);
        EToken2Interface eToken2 = anchorPhase.eToken2();
        bytes32 doctSymbol = anchorPhase.DOCT();
        require(eToken2.reissueAsset(doctSymbol, _doctValue), &#39;DOCT reissue failed&#39;);
        ERC20Interface doct = anchorPhase.doct();
        require(doct.transfer(address(anchorPhase), _doctValue), &#39;DOCT transfer to phase failed&#39;);
    }

    function executeExpansion(uint _anctValue) public {
        require(msg.sender == anchorVotes, &#39;Access denied&#39;);
        EToken2Interface eToken2 = anchorPhase.eToken2();
        bytes32 anctSymbol = anchorPhase.ANCT();
        require(eToken2.reissueAsset(anctSymbol, _anctValue), &#39;ANCT reissue failed&#39;);
        ERC20Interface anct = anchorPhase.anct();
        require(anct.transfer(address(anchorPhase), _anctValue), &#39;ANCT transfer to phase failed&#39;);
    }

    function execute(address _to, bytes memory _data) public {
        require(msg.sender == anchorVotes, &#39;Access denied&#39;);
        (bool success, bytes memory result) =  _to.call(_data);
        require(success, string(result));
    }
}
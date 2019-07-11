/**
 *Submitted for verification at Etherscan.io on 2019-07-09
*/

pragma solidity ^0.4.23;

pragma solidity ^0.4.23;

contract Operators
{
    mapping (address=>bool) ownerAddress;
    mapping (address=>bool) operatorAddress;

    constructor() public
    {
        ownerAddress[msg.sender] = true;
    }

    modifier onlyOwner()
    {
        require(ownerAddress[msg.sender]);
        _;
    }

    function isOwner(address _addr) public view returns (bool) {
        return ownerAddress[_addr];
    }

    function addOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));

        ownerAddress[_newOwner] = true;
    }

    function removeOwner(address _oldOwner) external onlyOwner {
        delete(ownerAddress[_oldOwner]);
    }

    modifier onlyOperator() {
        require(isOperator(msg.sender));
        _;
    }

    function isOperator(address _addr) public view returns (bool) {
        return operatorAddress[_addr] || ownerAddress[_addr];
    }

    function addOperator(address _newOperator) external onlyOwner {
        require(_newOperator != address(0));

        operatorAddress[_newOperator] = true;
    }

    function removeOperator(address _oldOperator) external onlyOwner {
        delete(operatorAddress[_oldOperator]);
    }
}

pragma solidity ^0.4.23;

contract CutieCoreInterface
{
    function isCutieCore() pure external returns (bool);

    function transferFrom(address _from, address _to, uint256 _cutieId) external;
    function transfer(address _to, uint256 _cutieId) external;

    function ownerOf(uint256 _cutieId) external view returns (address owner);

    function getCutie(uint40 _id) external view returns (
        uint256 genes,
        uint40 birthTime,
        uint40 cooldownEndTime,
        uint40 momId,
        uint40 dadId,
        uint16 cooldownIndex,
        uint16 generation
    );

    function getGenes(uint40 _id) external view returns (uint256 genes);
    function getCooldownEndTime(uint40 _id) external view returns (uint40 cooldownEndTime);
    function getCooldownIndex(uint40 _id) external view returns (uint16 cooldownIndex);
    function getGeneration(uint40 _id) external view returns (uint16 generation);
    function getOptional(uint40 _id) external view returns (uint64 optional);
    function changeGenes(uint40 _cutieId, uint256 _genes) external;
    function changeCooldownEndTime(uint40 _cutieId, uint40 _cooldownEndTime) external;
    function changeCooldownIndex(uint40 _cutieId, uint16 _cooldownIndex) external;
    function changeOptional(uint40 _cutieId, uint64 _optional) external;
    function changeGeneration(uint40 _cutieId, uint16 _generation)external;
    function createSaleAuction(uint40 _cutieId, uint128 _startPrice, uint128 _endPrice, uint40 _duration) external;

    function getApproved(uint256 _tokenId) external returns (address);
    function totalSupply() view external returns (uint256);
    function createPromoCutie(uint256 _genes, address _owner) external;
    function checkOwnerAndApprove(address _claimant, uint40 _cutieId, address _pluginsContract) external view;
    function breedWith(uint40 _momId, uint40 _dadId) public payable returns (uint40);
    function getBreedingFee(uint40 _momId, uint40 _dadId) public view returns (uint256);
    function createPromoCutieWithGeneration(uint256 _genes, address _owner, uint16 _generation) external;
    function restoreCutieToAddress(uint40 _cutieId, address _recipient) external;
    function createGen0Auction(uint256 _genes, uint128 startPrice, uint128 endPrice, uint40 duration) external;
    function createGen0AuctionWithTokens(uint256 _genes, uint128 startPrice, uint128 endPrice, uint40 duration, address[] allowedTokens) external;
    function createPromoCutieBulk(uint256[] _genes, address _owner, uint16 _generation) external;
}

pragma solidity ^0.4.23;

interface PluginsInterface
{
    function isPlugin(address contractAddress) external view returns(bool);
    function withdraw() external;
    function setMinSign(uint40 _newMinSignId) external;

    function runPluginOperator(
        address _pluginAddress,
        uint40 _signId,
        uint40 _cutieId,
        uint128 _value,
        uint256 _parameter,
        address _sender) external payable;
}


contract CoreOperatorProxy is Operators
{
    CutieCoreInterface public core;
    PluginsInterface public plugins;

    function setup(CutieCoreInterface _core, PluginsInterface _plugins) external onlyOwner
    {
        core = _core;
        plugins = _plugins;
    }

    function restoreCutieToAddress(uint40 _cutieId, address _recipient) external onlyOperator {
        core.restoreCutieToAddress(_cutieId, _recipient);
    }

    function createGen0Auction(uint256 _genes, uint128 startPrice, uint128 endPrice, uint40 duration) external onlyOperator {
        core.createGen0Auction(_genes, startPrice, endPrice, duration);
    }

    function createGen0AuctionWithTokens(uint256 _genes, uint128 startPrice, uint128 endPrice, uint40 duration, address[] allowedTokens) external onlyOperator
    {
        core.createGen0AuctionWithTokens(_genes, startPrice, endPrice, duration, allowedTokens);
    }

    function createPromoCutie(uint256 _genes, address _owner) external onlyOperator
    {
        core.createPromoCutie(_genes, _owner);
    }

    function createPromoCutieWithGeneration(uint256 _genes, address _owner, uint16 _generation) external onlyOperator
    {
        core.createPromoCutieWithGeneration(_genes, _owner, _generation);
    }

    function createPromoCutieBulk(uint256[] _genes, address _owner, uint16 _generation) external onlyOperator
    {
        core.createPromoCutieBulk(_genes, _owner, _generation);
    }

    function setMinSign(uint40 _newMinSignId) external onlyOperator
    {
        plugins.setMinSign(_newMinSignId);
    }
}
pragma solidity 0.8.6;

import "./ERC721.sol";
import "./ERC20.sol";

contract Test {
    mapping(address => bool) public managers;
    
    event ERC721TransferOut(ERC721 _contractAddress, address _to, uint256 _tokenId);
    event ERC20TransferOut(ERC20 _contractAddress, address _to, uint256 _amount);
    event EthWithdrawal(address _receiver, uint256 _amount);
    event ManagerAdded(address _manager);
    event ManagerRemoved(address _manager);
    
    constructor() {
        managers[msg.sender] = true;
    }

    modifier onlyManagers() {
        require(managers[msg.sender], "Only managers allowed");
        _;
    }

    function addManager(address _manager) public onlyManagers {
        managers[_manager] = true;
        emit ManagerAdded(_manager);
    }

    function removeManager(address _manager) public onlyManagers {
        managers[_manager] = false;
        emit ManagerRemoved(_manager);
    }

    function transferOutERC721(ERC721 _erc721ContractAddress, uint256 _tokenId, address _receiver) public onlyManagers {
        require(managers[_receiver], "Only managers allowed as receiver");
        _erc721ContractAddress.transferFrom(address(this), _receiver, _tokenId);
        emit ERC721TransferOut(_erc721ContractAddress, _receiver, _tokenId);
    }
    
    function transferOutERC20(ERC20 _erc20ContractAddress, uint256 _amount, address _receiver) public onlyManagers {
        require(managers[_receiver], "Only managers allowed as receiver");
        _erc20ContractAddress.transfer(_receiver, _amount);
        emit ERC20TransferOut(_erc20ContractAddress, _receiver, _amount);
    }
    
    function withdraw(address payable _receiver, uint256 _amount) public onlyManagers {
        if(_amount == 0)
            _amount = address(this).balance;
            
        _receiver.transfer(_amount);
        emit EthWithdrawal(_receiver, _amount);
    }
        
    fallback() external payable {
    }

    receive() external payable {
    }
}
pragma solidity 0.8.3;

import "./ERC721Map.sol";
import "./ProjectOwnerServiceInterface.sol";

contract ERC721NameService is ERC721Map {

    // Fee in wei for the name service
    uint256 public baseFee;

    address public ownerServiceAddress;

    constructor() public {
        baseFee = 0;
    }

    function setBaseFee(uint256 _fee) public onlyOwner {
        baseFee = _fee;
    }

    function setOwnerService(address _address) public onlyOwner {
        if(_address == address(0x0)) {
            ownerServiceAddress = address(0x0);
            return;
        }

        ProjectOwnerServiceInterface service = ProjectOwnerServiceInterface(_address);
        require(service.isProjectOwnerService());

        ownerServiceAddress = _address;
    }
    
    function getProjectFeeInWei(address _address) public view returns(uint256) {
        if(ownerServiceAddress != address(0x0)) {
            ProjectOwnerServiceInterface ownerService = ProjectOwnerServiceInterface(ownerServiceAddress);
            if(ownerService.isProjectRegistered(_address)) {
                return ownerService.getProjectFeeInWei(_address);
            }
        }

        return 0;
    }

    function setTokenName(address _address, uint256 _tokenId, string memory _nftName) public payable {
        uint256 projectFee = getProjectFeeInWei(_address);
        uint256 totalFee = projectFee + baseFee;
        require(msg.value >= totalFee);
        
        uint256 ourFee = totalFee - projectFee;

        if(projectFee > 0) {
            ProjectOwnerServiceInterface ownerService = ProjectOwnerServiceInterface(ownerServiceAddress);
            address projectOwner = ownerService.getProjectOwner(_address);
            addPendingWithdrawal(projectOwner, projectFee);
        }

        addPendingWithdrawal(owner, ourFee);
        _setTokenName(_address, _tokenId, _nftName);
    }

}
/**
 *Submitted for verification at hecoinfo.com on 2022-05-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

struct WithdrawRecord {
    uint256 id;
    address tokenContract;
    address withdrawAddress;
    uint256 amount;
    uint256 time;
}

struct Tax {
    uint256 frozen;
    uint256 balance;
    uint256 received;
}

struct Tpp {
    address owner_;
    address business;
    uint256 businessEndTime;
}

struct TppBusiness {
    address tokenContract;
    uint256 businessEndTime;
}

interface TaxController {

    function getPlatformRevenue(address _tokenContract, address _sender) external view returns (uint256 totalAllRevenue, Tax memory tax);

    function platformWithdraw(address _tokenContract) external;

/********************************************************************/

    function channelRevenue(address _tokenContract, address __sender) external view returns (Tax memory tax);

    function channelWithdraw(address _tokenContract, address _sender) external;

    function getWithdrawRecord(uint256 __withdrawId) external view returns (WithdrawRecord memory);

    function getWithdrawLength(address __sender) external view returns (uint256);

    function getWithdrawIdAtIndex(address __sender, uint256 __index) external view returns (uint256);

/********************************************************************/

    function tppRevenue(address _tokenContract, address __sender) external view returns (Tax memory tax);

    function tppWithdraw(address _tokenContract, address _sender) external;

    function getWithdrawTppRecord(uint256 __withdrawId) external view returns (WithdrawRecord memory);

    function getWithdrawTppLength(address __sender) external view returns (uint256);

    function getWithdrawTppIdAtIndex(address __sender, uint256 __index) external view returns (uint256);

    function getTppInfo(address _tokenContract) external view returns (Tpp memory);

    function getIdentity(address __sender) external view returns (string memory channel, string memory tppOwner, string memory tppBusiness);

    function getTppOwnerList(address __sender) external view returns (address[] memory);

    function getTppBusinessList(address __sender) external view returns (address[] memory);
}


contract TaxApi{

    address private _owner;
    address private _body;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (address __body) {
        _owner = msg.sender;
        _body = __body;
    }

    function getPlatformRevenueList(address[] memory _tokenContractList, address _sender) external view returns (uint256[10] memory totalAllRevenueList, Tax[10] memory taxList, address[10] memory tokenContractList)
    {
        require(_tokenContractList.length <= 10, "length Can't be greater than 10!");
        for (uint i=0; i<_tokenContractList.length; i++)
        {
            (totalAllRevenueList[i], taxList[i]) = TaxController(_body).getPlatformRevenue(_tokenContractList[i], _sender);
            tokenContractList[i] = _tokenContractList[i];
        }
    }

    function getPlatformRevenue(address _tokenContract, address _sender) external view returns (uint256 totalAllRevenue, Tax memory tax)
    {
        return TaxController(_body).getPlatformRevenue(_tokenContract, _sender);
    }

    function platformWithdraw(address _tokenContract) external
    {
        TaxController(_body).platformWithdraw(_tokenContract);
    }

/********************************************************************/

    function channelRevenueList(address[] memory _tokenContractList, address __sender) external view returns (Tax[20] memory list)
    {
        require(_tokenContractList.length <= 20, "length Can't be greater than 10!");
        for (uint i=0; i<_tokenContractList.length; i++)
        {
            list[i] = TaxController(_body).channelRevenue(_tokenContractList[i], __sender);
        }
    }

    function channelRevenue(address _tokenContract, address __sender) external view returns (Tax memory tax)
    {
        return TaxController(_body).channelRevenue(_tokenContract, __sender);
    }

    function channelWithdraw(address _tokenContract) external
    {
        TaxController(_body).channelWithdraw(_tokenContract, msg.sender);
    }

    function getWithdrawLength(address __sender) external view returns (uint256)
    {
        return TaxController(_body).getWithdrawLength(__sender);
    }

    function getWithdrawRecords(uint256[] memory __withdrawIds) external view returns (WithdrawRecord[20] memory)
    {
        WithdrawRecord[20] memory list;
        for (uint i=0; i<__withdrawIds.length; i++)
        {
            list[i] = TaxController(_body).getWithdrawRecord(__withdrawIds[i]);
        }
        return list;
    }

    function getWithdrawRecordsInIndexs(address __sender, uint256[] memory __indexs) external view returns (WithdrawRecord[20] memory)
    {
        uint256[20] memory __withdrawIds;
        for (uint i=0; i<__indexs.length; i++)
        {
            if (i == 20) break;
            __withdrawIds[i] = TaxController(_body).getWithdrawIdAtIndex(__sender,__indexs[i]);
        }
        
        WithdrawRecord[20] memory list;
        for (uint i=0; i<__withdrawIds.length; i++)
        {
            list[i] = TaxController(_body).getWithdrawRecord(__withdrawIds[i]);
        }
        return list;
    }

    function tppRevenueList(address[] memory _tokenContractList, address __sender) external view returns (Tax[10] memory list)
    {
        require(_tokenContractList.length <= 10, "length Can't be greater than 10!");
        for (uint i=0; i<_tokenContractList.length; i++)
        {
            list[i] = TaxController(_body).tppRevenue(_tokenContractList[i], __sender);
        }
    }

    function tppRevenue(address _tokenContract, address __sender) external view returns (Tax memory tax)
    {
        return TaxController(_body).tppRevenue(_tokenContract, __sender);
    }

    function tppWithdraw(address _tokenContract) external
    {
        TaxController(_body).tppWithdraw(_tokenContract, msg.sender);
    }

    function getWithdrawTppLength(address __sender) external view returns (uint256)
    {
        return TaxController(_body).getWithdrawTppLength(__sender);
    }

    function getWithdrawTppRecords(uint256[] memory __withdrawIds) external view returns (WithdrawRecord[20] memory)
    {
        WithdrawRecord[20] memory list;
        for (uint i=0; i<__withdrawIds.length; i++)
        {
            list[i] = TaxController(_body).getWithdrawTppRecord(__withdrawIds[i]);
        }
        return list;
    }

    function getWithdrawTppRecordsInIndexs(address __sender, uint256[] memory __indexs) external view returns (WithdrawRecord[20] memory)
    {
        uint256[20] memory __withdrawIds;
        for (uint i=0; i<__indexs.length; i++)
        {
            if (i == 20) break;
            __withdrawIds[i] = TaxController(_body).getWithdrawTppIdAtIndex(__sender,__indexs[i]);
        }
        
        WithdrawRecord[20] memory list;
        for (uint i=0; i<__withdrawIds.length; i++)
        {
            list[i] = TaxController(_body).getWithdrawTppRecord(__withdrawIds[i]);
        }
        return list;
    }

    function getTppInfo(address _tokenContract) external view returns (Tpp memory)
    {
        return TaxController(_body).getTppInfo(_tokenContract);
    }

    function getIdentity(address __sender) external view returns (string memory channel, string memory tppOwner, string memory tppBusiness)
    {
        return TaxController(_body).getIdentity(__sender);
    }

    function getTppOwnerList(address __sender) external view returns (address[] memory)
    {
        return TaxController(_body).getTppOwnerList(__sender);
    }

    function getTppBusinessList(address __sender) external view returns (TppBusiness[] memory)
    {
        address[] memory __tokenContracts = TaxController(_body).getTppBusinessList(__sender);
        TppBusiness[] memory list = new TppBusiness[](__tokenContracts.length);
        for (uint256 i=0; i<__tokenContracts.length; i++)
        {
            address tokenContract = __tokenContracts[i];
            list[i] = TppBusiness(tokenContract, this.getTppInfo(tokenContract).businessEndTime);
        }
        return list;
    }
}
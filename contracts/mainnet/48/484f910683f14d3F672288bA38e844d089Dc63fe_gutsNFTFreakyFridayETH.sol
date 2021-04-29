/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

pragma solidity ^0.6.2;

contract gutsNFTFreakyFridayETH {

    address public overlordCasper;

    mapping (address => investorStruct) public FFDefiInvestors;

    event FreakyInvestorRegistered (
        address investorAddress,
        string linkToSlackImage,
        uint timestamp
    );

    struct investorStruct {
        address addressInvestor;
        string linkToSlackImage;
        bool isRegistered;
        uint timestamp;
    }

    constructor() public {
        overlordCasper = msg.sender;
    }

    function registerAsFreakyFridayFicheInvestor(
        string calldata _linkToSlackImage
    ) external {

        // FFDefiInvestors[msg.sender] 
        investorStruct memory investorD = investorStruct({
            addressInvestor: msg.sender,
            linkToSlackImage: _linkToSlackImage,
            isRegistered: true,
            timestamp: block.timestamp
        });

        // store investor data in mapping
        FFDefiInvestors[msg.sender] = investorD;

        emit FreakyInvestorRegistered(
            msg.sender,
            _linkToSlackImage,
            block.timestamp
        );

    }

    function viewURLofInvestor( 
        address addressInvestor
    ) public virtual view returns(
        string memory _urlSlack
        ) 
    {
        _urlSlack = FFDefiInvestors[addressInvestor].linkToSlackImage;
    }

}
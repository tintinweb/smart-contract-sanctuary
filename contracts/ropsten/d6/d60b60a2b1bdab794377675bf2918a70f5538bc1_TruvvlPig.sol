/**
 *Submitted for verification at Etherscan.io on 2021-03-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract TruvvlPig {
    event NewLicense(bytes32 ipfsHash, uint8 licenseType);

    struct License {
        bytes32 ipfsHash;
        uint8 licenseType;
    }

    License[] public licenses;

    mapping(uint256 => address) public licenseToOwner;
    mapping(address => uint256[]) public buyerToLicense;
    mapping(address => uint256) ownerLicenseCount;
    mapping(address => uint256) buyerLicenseCount;
    mapping(bytes32 => bool) public hashExists;

    uint256 licenseFee = 0.01 ether;
    address devWallet = 0xF02557dE34Fb5D4E00A7d2001235A0C8f74B0Efc;
    address daoWallet = 0xaf7B8f71C1d9C541D2696DEABe7F1ee0667bd568;

    // @notice Create a license
    // @dev License type can curently only take two values, but will later offer more options
    // @param ipfsHash Hash of the post to license
    // @param licenseType Which use cases does the license include
    function createLicense(bytes32 ipfsHash, uint8 licenseType) public {
        // @dev Require that ipfsHash does not exist yet
        require(!hashExists[ipfsHash], 'A post can only be licensed once');
        // @dev Save ipfsHash and licenseType to licenses
        licenses.push(License(ipfsHash, licenseType));
        uint256 id = licenses.length - 1;
        licenseToOwner[id] = msg.sender;
        hashExists[ipfsHash] = true;
        ownerLicenseCount[msg.sender]++;
        emit NewLicense(ipfsHash, licenseType);
    }

    // @notice read function to view all licenses granted by a specific address
    // @param address Wallet of the author who licenses the post
    function getLicensesByOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](ownerLicenseCount[_owner]);
        uint256 counter = 0;
        for (uint256 i = 0; i < licenses.length; i++) {
            if (licenseToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    // @notice Fetch details for a license
    // @dev Returns the contents of the struct
    // @param index ID of the license to fetch
    // @return ipfsHash in bytes format, licenseType as number, author wallet
    function getLicenseDetails(uint256 index)
        external
        view
        returns (
            bytes32,
            uint8,
            address
        )
    {
        License storage license = licenses[index];

        return (license.ipfsHash, license.licenseType, licenseToOwner[index]);
    }

    // @notice Pay ether to buy a license
    // @dev Function called
    // @param index ID of the license to buy
    // @param beneficiary Usually the wallet of the frontend that receives the comission
    function buyLicense(uint256 index, address beneficiary) external payable {
        require(msg.value == licenseFee, 'License fee incorrect');
        require(
            msg.sender != licenseToOwner[index],
            'You cannot buy your own license'
        );
        uint256[] memory boughtLicenses = buyerToLicense[msg.sender];
        for (uint256 i = 0; i < buyerLicenseCount[msg.sender]; i++) {
            require(
                boughtLicenses[i] != index,
                'You can only buy a license once'
            );
        }
        // @notice: 80% to the author
        (bool ownerSent, ) =
            licenseToOwner[index].call{value: (msg.value / 10) * 8}('');
        require(ownerSent, 'Failed to send Ether');
        // @notice 10% fee paid to the beneficiary set in the transaction to incentivize frontends building on the protocol
        (bool beneficairySent, ) =
            beneficiary.call{value: (msg.value / 10)}('');
        require(beneficairySent, 'Failed to send Ether');
        // @notice 5% fee used for buybacks + token burns to reward holders of our native token
        (bool daoSent, ) = daoWallet.call{value: (msg.value / 20)}('');
        require(daoSent, 'Failed to send Ether');
        // @notice 5% fee to the governance treasury to finance the continued development of the protocol
        (bool devSent, ) = devWallet.call{value: (msg.value / 20)}('');
        require(devSent, 'Failed to send Ether');

        buyerToLicense[msg.sender].push(index);
        buyerLicenseCount[msg.sender]++;
        // @dev TODO: Emmit event
    }

    // @notice fetch licenses bought by a specific wallet
    // @param address wallet of the buyer
    // @return array of IDs of licenses bought
    function getLicensesByBuyer(address _buyer)
        external
        view
        returns (uint256[] memory)
    {
        return buyerToLicense[_buyer];
    }

    // @notice Get the total number of licenses available
    // @return length of the licenses array
    function getLicenseCount() external view returns (uint256) {
        return licenses.length;
    }
}
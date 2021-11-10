// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

contract Certi {
    struct Certificate {
        string ipfs;
        uint256 issuer;
        uint256 issuetime;
        uint256 validtill;
    }

    address[] public institutes;
    mapping(string => Certificate) public certificates;
    mapping(address => uint256) public institutes_reverse;

    constructor() {
        institutes.push(address(0));
    }

    function generateCert(
        string calldata _ipfs,
        uint256 _validtill,
        string calldata _cerdID
    ) public {
        require(certificates[_cerdID].issuetime == 0);
        if (institutes_reverse[msg.sender] == 0) {
            institutes_reverse[msg.sender] = institutes.length;
            institutes.push(msg.sender);
        }
        certificates[_cerdID] = Certificate(
            _ipfs,
            institutes_reverse[msg.sender],
            block.timestamp,
            _validtill
        );
    }

    function revoke(string calldata _cerdID) public {
        require(institutes[certificates[_cerdID].issuer] == msg.sender);
        certificates[_cerdID].validtill = 1;
    }

    function reinstate(string calldata _cerdID, uint256 _validtill) public {
        require(institutes[certificates[_cerdID].issuer] == msg.sender);
        certificates[_cerdID].validtill = _validtill;
    }

    function changeaddress(address _newaddress) public {
        require(institutes_reverse[msg.sender] > 0);
        institutes[institutes_reverse[msg.sender]] = _newaddress;
        institutes_reverse[_newaddress] = institutes_reverse[msg.sender];
        institutes_reverse[msg.sender] = 0;
    }

    function verify(string calldata _cerdID)
        external
        view
        returns (
            string memory,
            address,
            uint256,
            uint256
        )
    {
        Certificate memory cert = certificates[_cerdID];
        return (
            cert.ipfs,
            institutes[cert.issuer],
            cert.issuetime,
            cert.validtill
        );
    }
}
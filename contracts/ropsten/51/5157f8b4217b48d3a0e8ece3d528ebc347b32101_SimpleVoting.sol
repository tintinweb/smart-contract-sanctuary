pragma solidity 0.4.24;

contract SimpleVoting {

    string public constant description = "abc";

    struct Cert {
        string program;
        string subjects;
        string dateStart;
        string dateEnd;
    }

    mapping  (string => Cert[]) certs;

    address owner;

    constructor() public {
        owner = msg.sender;
    }

    function setCertificate(string memory memberId, string memory program, string memory subjects, string memory dateStart, string memory dateEnd) public {
        require(msg.sender == owner);
        certs[memberId].push(Cert(program, subjects, dateStart, dateEnd));
    }

    function getCertificate(string memory memberId) public view returns (string memory) {
        Cert[] memory memberCerts = certs[memberId];
        if (memberCerts.length == 0) {
            return "Certificate not found";
        }
        string memory result;
        string memory delimiter;
        for (uint i = 0; i < memberCerts.length; i++) {
            result = string(abi.encodePacked(
                result,
                delimiter,
                "This is to certify that member ID in Sessia: ",
                memberId,
                " between ",
                memberCerts[i].dateStart,
                " and ",
                memberCerts[i].dateEnd,
                " successfully finished the educational program ",
                memberCerts[i].program,
                " that included the following subjects: ",
                memberCerts[i].subjects,
                ". The President of the KICKVARD UNIVERSITY Narek Sirakanyan"
            ));
            delimiter = "; ";
        }

        return result;
    }
}
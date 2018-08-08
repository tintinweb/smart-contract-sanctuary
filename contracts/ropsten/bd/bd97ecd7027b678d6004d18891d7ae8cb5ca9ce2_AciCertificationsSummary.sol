pragma solidity ^0.4.24;

contract AciCertificationsSummary {

    address private owner;

    struct DataSummary {
        string block_hash;
        string tree_root;
    }


    mapping (uint => DataSummary) public certs;

    uint private count;


    constructor() public {
        owner = msg.sender;
    }


    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    function add_certifications(
        string _block_hash,
        string _tree_root
        )
        public onlyOwner {

        bytes memory block_bytes = bytes(_block_hash);
        bytes memory tree_bytes = bytes(_tree_root);

        require(block_bytes.length > 0,    "hash block not valid");
        require(tree_bytes.length > 0,   "hash merkel tree not valid");

        certs[count] = DataSummary(_block_hash, _tree_root);

        count = count + 1;
    }
}
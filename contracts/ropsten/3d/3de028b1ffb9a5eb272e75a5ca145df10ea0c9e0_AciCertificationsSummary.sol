pragma solidity ^0.4.24;

contract AciCertificationsSummary {

    address private owner;

    struct DataSummary {
        string block_hash;
        string tree_root;
    }

    DataSummary[] registry_data_summary;


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

        require(block_bytes.length > 0,    &quot;hash block not valid&quot;);
        require(tree_bytes.length > 0,   &quot;hash merkel tree not valid&quot;);

        DataSummary memory data_summary;
        data_summary.block_hash = _block_hash;
        data_summary.tree_root = _tree_root;

        registry_data_summary.push(data_summary);
    }
}
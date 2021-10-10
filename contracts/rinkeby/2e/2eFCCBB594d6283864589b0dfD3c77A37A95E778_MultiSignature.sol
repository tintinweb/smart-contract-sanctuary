/**
 *Submitted for verification at Etherscan.io on 2021-10-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract MultiSignature {
    // z
    address constant public a = 0xa8c395123FD6081426a4bbB98fd4b3c3243ff2c1; 
    // K
    address constant public b = 0xC1a6A1DAA5A1aC828b6a5Ad1C59bc4bBF7be6723;
    // H
    address constant public c = 0x892E96B6f77514B363c2DEC302dddD78e0D5152d;

    struct Proposal {
        string symbol;
        string description;
        address operator;
        bool arg;
        uint8 approved; 
        uint8 disapproved;
    }

    Proposal[] public proposals;

    mapping (uint=> mapping (address => bool)) public isVoted;

    modifier only_admin() {
        require(msg.sender == a || msg.sender == b || msg.sender == c, "Not admin");
        _;
    }

    modifier not_voted(uint _index) {
        require(!isVoted[_index][msg.sender], "Had voted");
        _;
    }

    event Voted(address sender, uint index, bool isApproved);

    function get_proposals_length() external view returns (uint) {
        return proposals.length;
    }

    function create(string memory _symbol, string memory _desc, address _operator, bool _arg) external only_admin{
        proposals.push(Proposal(_symbol, _desc, _operator, _arg, 0, 0));
    }

    function vote(uint _index, bool _isApproved) external only_admin not_voted(_index){
        if(_isApproved){
            proposals[_index].approved += 1;
        } else {
            proposals[_index].disapproved += 1;
        }

        isVoted[_index][msg.sender] = true;

        emit Voted(msg.sender, _index, _isApproved);
    }

    function is_apporved(uint _index) view external returns(string memory _symbol, uint _approved, address _operator, bool _arg){
        Proposal memory prp = proposals[_index];
        _symbol = prp.symbol;
        _approved = prp.approved;
        _operator = prp.operator;
        _arg = prp.arg;
    }

}
pragma solidity ^0.4.17;

contract ERC20Frag {
    function approve(address spender, uint tokens) public returns (bool);
}

contract BountyFrag {
    function issueAndActivateBounty(
        address _issuer,
        uint _deadline,
        string _data,
        uint256 _fulfillmentAmount,
        address _arbiter,
        bool _paysTokens,
        address _tokenContract,
        uint256 _value
        ) public payable returns (uint);
}

contract TokenBounty {
    
    function issueAndActivateTokenBounty(
        address _issuer,
        uint _deadline,
        string _data,
        uint256 _fulfillmentAmount,
        address _arbiter,
        bool _paysTokens,
        address _tokenContract,
        uint256 _value,
        address _bountyContract
        ) public payable returns (uint) {
        require(ERC20Frag(_tokenContract).approve(_bountyContract, _fulfillmentAmount));
        return BountyFrag(_bountyContract).issueAndActivateBounty(
            _issuer,
            _deadline,
            _data,
            _fulfillmentAmount,
            _arbiter,
            _paysTokens,
            _tokenContract,
            _value
        );
    }

    function() public payable {
        revert();
    }
}
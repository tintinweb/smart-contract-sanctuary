/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

pragma solidity ^0.5.0;

interface IDarkEnergyCrystals {

    function mint(uint256 _quantity) external;
    function burn(uint256 _quantity) external;
    function unlock(address _holder, uint256 _quantity) external;
}

contract CrystalMinter {

    IDarkEnergyCrystals crystals;
    address signer1;
    address signer2;
    address signer3;

    struct SubstitutionProposal {
        address proposer;
        address affirmer;
        address retiree;
        address replacement;
    }

    mapping(address => SubstitutionProposal) proposals;

    constructor(address _crystalsAddr, address _signer1, address _signer2, address _signer3) public {
        crystals = IDarkEnergyCrystals(_crystalsAddr);
        signer1 = _signer1;
        signer2 = _signer2;
        signer3 = _signer3;
    }

    function mint(uint256 _quantity) public onlySigner() {
        crystals.mint(_quantity);
    }

    function burn(uint256 _quantity) public onlySigner() {
        crystals.burn(_quantity);
    }

    function unlock(address _holder, uint256 _quantity) public onlySigner() {
        crystals.unlock(_holder, _quantity);
    }

    function proposeSubstitution(
                address _affirmer,
                address _retiree,
                address _replacement
            )
                public
                onlySigner
                isSigner(_affirmer)
                isSigner(_retiree)
                notSigner(_replacement)
    {
        address _proposer = msg.sender;

        require(_affirmer != _proposer, "CrystalMinter: Affirmer Is Proposer");
        require(_affirmer != _retiree, "CrystalMinter: Affirmer Is Retiree");
        require(_proposer != _retiree, "CrystalMinter: Retiree Is Proposer");

        proposals[_proposer] = SubstitutionProposal(_proposer, _affirmer, _retiree, _replacement);
    }

    function withdrawProposal() public onlySigner {
        delete proposals[msg.sender];
    }

    function withdrawStaleProposal(address _oldProposer) public onlySigner notSigner(_oldProposer) {
        delete proposals[_oldProposer];
    }

    function acceptProposal(address _proposer) public onlySigner isSigner(_proposer) {
        SubstitutionProposal storage proposal = proposals[_proposer];

        require(proposal.affirmer == msg.sender, "CrystalMinter: Not Affirmer");

        if (signer1 == proposal.retiree) {
            signer1 = proposal.replacement;
        } else if (signer2 == proposal.retiree) {
            signer2 = proposal.replacement;
        } else if (signer3 == proposal.retiree) {
            signer3 = proposal.replacement;
        }

        delete proposals[_proposer];
    }

    modifier onlySigner() {
        require(msg.sender == signer1 ||
                msg.sender == signer2 ||
                msg.sender == signer3,
                "CrystalMinter: Not Signer");
        _;
    }

    modifier isSigner(address _addr) {
        require(_addr == signer1 ||
                _addr == signer2 ||
                _addr == signer3,
                "CrystalMinter: Addr Not Signer");
        _;
    }

    modifier notSigner(address _addr) {
        require(_addr != signer1 &&
                _addr != signer2 &&
                _addr != signer3,
                "CrystalMinter: Addr Is Signer");
        _;
    }
}
pragma solidity >=0.5.0 <0.6.0;

// TODO define a contract call to the zokrates generated solidity contract <Verifier> or <renamedVerifier>
import "./verifier.sol";
import "./ERC721Mintable.sol";

interface iVerifier {
    function verifyTx(uint[2] calldata a, uint[2][2] calldata b, uint[2] calldata c, uint[2] calldata input) external returns (bool);
}

// TODO define another contract named SolnSquareVerifier that inherits from your ERC721Mintable class
contract SolnSquareVerifier is RealStateMarketplace {
    
    iVerifier Verifier;

    function setVerifier(address verifierAddress) external {
        Verifier = iVerifier(verifierAddress);
    }

    // TODO define a solutions struct that can hold an index & an address
    struct solution {
        uint256 _index;
        address _owner;
    }

    // TODO define a mapping to store unique solutions submitted
    mapping (bytes32 => solution) private _solutions;
    mapping (bytes32 => bool) private _uniqueSolutions;

    // TODO Create an event to emit when a solution is added
    event SolutionAdded(uint256 _index, address _address);

    // TODO Create a function to add the solutions to the array and emit the event
    function addSolution(uint256 index, address owner) public {
        bytes32 key = keccak256(abi.encodePacked(index, owner));
        _uniqueSolutions[key] = true;
        _solutions[key]._index = index;
        _solutions[key]._owner = owner;
        emit SolutionAdded(index, owner);
    }

    // TODO Create a function to mint new NFT only after the solution has been verified
    //  - make sure the solution is unique (has not been used before)
    //  - make sure you handle metadata as well as tokenSuplly
    function mintNFT(
            uint256 index,
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[2] memory input
        ) public {
        bool answer = Verifier.verifyTx(a, b, c, input);
        require(answer == true, "Operation failed, can not verify sender");
        bytes32 key = keccak256(abi.encodePacked(index, msg.sender));
        require(_uniqueSolutions[key] == false, "Solution has already been used");
        addSolution(index, msg.sender);
        bool status = mint(msg.sender, index);
        require(status = true, "NFT could not be minted");
    }
}
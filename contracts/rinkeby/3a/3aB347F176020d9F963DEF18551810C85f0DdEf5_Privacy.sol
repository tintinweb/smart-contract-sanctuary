/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

pragma solidity ^0.8.0;


contract Privacy {
    
    address [] public solvers;
    mapping(address => bool) public solverExists;
    uint256 MAX_SOLVERS = 10;
    bytes private password;
    
    constructor(bytes memory _password){
        password = _password;
    }
    
    function guessPassword(string calldata _guess) public returns (bool){
        if (keccak256(password) == keccak256(bytes(_guess))){
            addSolver(msg.sender);
            return true;
        }else{
            return false;
        }
    }
    
    function addSolver(address _solver) internal {
        if (solvers.length < 10 && !solverExists[_solver]){
            solvers.push(_solver);
            solverExists[_solver] = true;
        }
    }

}
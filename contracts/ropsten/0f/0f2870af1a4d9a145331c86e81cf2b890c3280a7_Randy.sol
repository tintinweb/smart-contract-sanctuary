pragma solidity >0.4.x;

contract Randy {
    
    uint e = 65537;
    
    uint[] public openProblems;
    
    function submitProblem(uint n) public {
        require(n != 0);
        openProblems.push(n);
    }
    
    function solveProblem(uint index) public {
        uint lastIndex = openProblems.length - 1;
        uint lastProblem = openProblems[lastIndex];
        openProblems.pop();
        if (index != lastIndex) {
            openProblems[index] = lastProblem;
        }
    }
    
    function checkProblemsSolved() public view returns(bool) {
        return openProblems.length == 0;
    }
    
}
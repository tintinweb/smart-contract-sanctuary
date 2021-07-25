//SourceUnit: RaiseCapital.sol

/*
██████╗  █████╗ ██╗███████╗███████╗     ██████╗ █████╗ ██████╗ ██╗████████╗ █████╗ ██╗
██╔══██╗██╔══██╗██║██╔════╝██╔════╝    ██╔════╝██╔══██╗██╔══██╗██║╚══██╔══╝██╔══██╗██║
██████╔╝███████║██║███████╗█████╗      ██║     ███████║██████╔╝██║   ██║   ███████║██║
██╔══██╗██╔══██║██║╚════██║██╔══╝      ██║     ██╔══██║██╔═══╝ ██║   ██║   ██╔══██║██║
██║  ██║██║  ██║██║███████║███████╗    ╚██████╗██║  ██║██║     ██║   ██║   ██║  ██║███████╗
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚══════╝     ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝

Smart Contract: Raise Capital
*/
pragma solidity >=0.4.22 <=0.8.0;
contract RaiseCapital {

    function multisend(uint256[] memory amounts, address payable[] memory receivers) payable public {
        assert(amounts.length == receivers.length);
        assert(receivers.length <= 100);
        for (uint i = 0; i < receivers.length; i++) {
            receivers[i].transfer(amounts[i]);
        }
    }

    function f() public pure returns (string memory){
        return "method f()";
    }
    function g() public pure returns (string memory){
        return "method g()";
    }
}
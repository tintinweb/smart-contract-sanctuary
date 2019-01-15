pragma solidity ^0.5.0;

// Check if we are on Constantinople!
// <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="4520312d203722303c0528242c296b262a28">[email&#160;protected]</a>

contract HelloWorld{
    function Hello() public pure returns (string memory){
        return ("Hello World");
    }
}

contract ConstantinopleCheck{
    
    address public DeployedContractAddress;
    
    function deploy() public {
        // hex of hello world deploy bytecode
        bytes memory code = hex&#39;608060405234801561001057600080fd5b50610124806100206000396000f3fe6080604052348015600f57600080fd5b50600436106044577c01000000000000000000000000000000000000000000000000000000006000350463bcdfe0d581146049575b600080fd5b604f60c1565b6040805160208082528351818301528351919283929083019185019080838360005b8381101560875781810151838201526020016071565b50505050905090810190601f16801560b35780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b60408051808201909152600b81527f48656c6c6f20576f726c6400000000000000000000000000000000000000000060208201529056fea165627a7a72305820569c1233dc571997cbd1fa15675cd16b4cacd5615abb6c991dd85a516af1ecc80029&#39;;
        uint len = code.length;
        address deployed;
        assembly{
            deployed := create2(0, add(code, 0x20), len, "Hello Constantinople!")
        }
        DeployedContractAddress = deployed;
    }
    
    // returns true if we are on constantinople!
    function IsItConstantinople() public view returns (bool, bytes32){
        address target = address(this);
        bytes32 hash;
        assembly{
            hash := extcodehash(target)
        }
        
        // force return hash so the optimizer doesnt skip extcodehash OP
        return (true, hash);
    }
    
    function Hello() public view returns (string memory) {
        return (HelloWorld(DeployedContractAddress).Hello());
    }
    
    
    
}
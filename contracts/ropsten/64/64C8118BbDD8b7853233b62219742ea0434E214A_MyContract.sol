/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

// 声明solidity版本
pragma solidity >=0.8.6;

// 声明智能合约MyContractu，合约的所有代码都包含在花括号中。
contract MyContract {

    // 声明一个名为value的状态变量
    string value;

    // 合约构造函数，每当将合约部署到网络时都会调用它。
    // 此函数具有public函数修饰符，以确保它对公共接口可用。
    // 在这个函数中，我们将公共变量value的值设置为“myValue”。
    constructor() public {
        value = "myVale";
    }

    // 本函数读取值状态变量的值。可见性设置为public，以便外部帐户可以访问它。
    // 它还包含view修饰符并指定一个字符串返回值。
    function get() public view returns(string memory ) {
        return value;
    }

    // 本函数设置值状态变量的值。可见性设置为public，以便外部帐户可以访问它。
    function set(string memory _value) public {
        value = _value;
    }
}
/**
 *Submitted for verification at polygonscan.com on 2021-12-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Quest {

    struct Agent {
        int256 location;
        bool register;
    }

    mapping(address => Agent) private agents;

    // lista de eventos
    event WelcomeBack();
    event TakeOff();
    event Message(string message);

    // lista de planetas
    string private earth;
    string private jupiter;
    string private neptune;
    string private saturn;
    string private mars;
    string private venus;
    string private uranus;
    string private mercury;

    int256 private m_jupiter = 289448041;
    int256 private m_neptune = 23456;
    int256 private m_saturn = 1234565;
    int256 private m_mars = 123432;
    int256 private m_venus = 27347;
    int256 private m_uranus = 3945693506;
    int256 private m_mercury = 3459340630235;
    int256 private m_galaxy = 868344123;

    constructor(string[] memory planets) {
        earth = planets[0];
        jupiter = planets[1];
        neptune = planets[2];
        saturn = planets[3];
        mars = planets[4];
        venus = planets[5];
        uranus = planets[6];
        mercury = planets[7];
    }

    modifier tookOff() {
        require(agents[msg.sender].register, "you have to start mission firt");
        _;
    }

    function takingOff() public {
        agents[msg.sender] = Agent(m_galaxy, true);
        emit TakeOff();
    }

    function Jupiter() public tookOff {
        require(agents[msg.sender].location % m_jupiter == 0, "no landing possible");
        emit Message("Welcome on Jupiter! Open to the following link for seeing our magic planet");
        emit Message(jupiter);
        agents[msg.sender].location = 670482624;
    }

    function Neptune() public tookOff {
        require(agents[msg.sender].location % m_neptune == 0, "no landing possible");
        emit Message("Welcome on Neptune! Open to the following link for seeing our magic planet");
        emit Message(neptune);
        agents[msg.sender].location = 456457;
    }

    function Uranus() public tookOff {
        require(agents[msg.sender].location % m_uranus == 0, "no landing possible");
        emit Message("Welcome on Uranus! Open to the following link for seeing our magic planet");
        emit Message(uranus);
        agents[msg.sender].location = 5693;
    }

    function Saturn() public tookOff {
        require(agents[msg.sender].location % m_saturn == 0, "no landing possible");
        emit Message("Welcome on Saturn! Open to the following link for seeing our magic planet");
        emit Message(saturn);
        agents[msg.sender].location = 1010402020;
    }

    function Mercury() public tookOff {
        require(agents[msg.sender].location % m_mercury == 0, "no landing possible");
        emit Message("Welcome on Mercury! Open to the following link for seeing our magic planet");
        emit Message(mercury);
        agents[msg.sender].location = 2772375;
    }

    function Venus() public tookOff {
        require(agents[msg.sender].location % m_venus == 0, "no landing possible");
        emit Message("Welcome on Venus! Open to the following link for seeing our magic planet");
        emit Message(venus);
        agents[msg.sender].location = 999;
    }

    function Mars() public tookOff {
        require(agents[msg.sender].location % m_mars == 0, "no landing possible");
        emit Message("Welcome on Mars! Open to the following link for seeing our magic planet");
        emit Message(mars);
        agents[msg.sender].location = 13230828;
    }

    function landing() public tookOff {
        require(agents[msg.sender].location % 234 == 0, "no landing possible");
        emit WelcomeBack();
        agents[msg.sender].location = 1;
    }
    

}
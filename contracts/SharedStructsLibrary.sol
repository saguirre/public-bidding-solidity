// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

library SharedStructs {
    struct Citizen {
        string ci;
        string name;
        string lastName;
        uint256 birthDate;
        address citizenAddress;
        bool approved;
        bool voted;
    }

    struct Proposal {
        string name;
        string lineOfWork;
        string description;
        uint256 voteCount;
        uint256 budget;
    }

    struct Tax {
        string name;
        string lineOfWork;
        uint256 amount;
        uint256 monthlyExpiration;
        uint256 monthlyInterest;
        bool active;
    }
}

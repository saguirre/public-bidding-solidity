// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./RegulatoryEntity.sol";
import "./TaxEntity.sol";

contract Construction {
    string public name;
    string public lineOfWork;
    string public description;
    uint256 public initialBudget;
    address payable owner;
    address factoryAddress;
    bool started = false;
    address[] designatedProviders;
    RegulatoryEntity regulatoryEntity;
    TaxEntity taxEntity;
    bool ownerApprovedClose = false;
    bool regulatoryEntityApprovedClose = false;
    bool paymentToProviderMade = false;

    constructor(
        string memory _name,
        string memory _lineOfWork,
        string memory _description,
        uint256 _budgetCost,
        address regulatoryEntityAddress,
        address taxEntityAddress,
        address _owner
    ) {
        name = _name;
        lineOfWork = _lineOfWork;
        description = _description;
        initialBudget = _budgetCost;
        factoryAddress = msg.sender;
        owner = payable(_owner);
        regulatoryEntity = RegulatoryEntity(regulatoryEntityAddress);
        taxEntity = TaxEntity(taxEntityAddress);
    }

    modifier onlyIfNotFunded() {
        require(
            address(this).balance < initialBudget,
            "Este contrato ya recibio suficientes fondos"
        );
        _;
    }

    modifier costs() {
        require(
            msg.value >= initialBudget,
            "No ha enviado suficiente Ether para financiar la obra"
        );

        _;
        if (msg.value > initialBudget)
            payable(msg.sender).transfer(msg.value - initialBudget);
    }

    modifier isOwner() {
        require(
            msg.sender == owner,
            "Esta operacion solo puede ser realizada por el owner del contrato"
        );
        _;
    }

    modifier canCloseConstruction() {
        require(
            ownerApprovedClose,
            "El dueno de la obra no ha aprobado el cierre"
        );
        require(
            regulatoryEntityApprovedClose,
            "El estado no ha aprobado el cierre"
        );
        require(
            paymentToProviderMade,
            "Aun no se han efectuado pagos al proveedor elegido"
        );
        _;
    }

    event ConstructionCreated(
        string name,
        string lineOfWork,
        string description,
        uint256 budget
    );

    event ConstructionSelfDestructed(
        string name,
        string lineOfWork,
        string description,
        uint256 budget
    );

    function close() public canCloseConstruction {
        selfdestructConstruction();
    }

    function fundConstruction() public payable onlyIfNotFunded costs {
        started = true;
        emit ConstructionCreated(name, lineOfWork, description, msg.value);
    }

    modifier hasStarted() {
        require(started, "La obra no ha comenzado todavia");
        _;
    }

    function selectProviders(
        address firstProvider,
        address secondProvider,
        address thirdProvider
    ) public isOwner hasStarted {
        // Una vez comenzada el dueño de la obra debe indicar tres address de proveedores de servicios de los cuales
        // el estado elegirá uno y le pagará por la realización de la obra.
        designatedProviders = [firstProvider, secondProvider, thirdProvider];
    }

    function getDesignatedProviders()
        public
        view
        hasStarted
        returns (address[] memory)
    {
        return designatedProviders;
    }

    modifier isRegulatoryEntity() {
        require(
            msg.sender == address(regulatoryEntity),
            "Esta accion solo puede ser realizada por el Estado"
        );
        _;
    }

    event ProviderPayed(address provider, uint256 amount);

    function approveProviderPayment(address provider)
        public
        isRegulatoryEntity
    {
        require(
            providerExists(provider),
            "El proveedor no es ninguno de los proveedores designados por el dueno de la obra"
        );

        require(address(this).balance >= initialBudget, "No existe Ether suficiente para pagar a los proveedores");
        payable(provider).transfer(initialBudget);
        paymentToProviderMade = true;
        emit ProviderPayed(provider, initialBudget);
    }

    function providerExists(address provider) private view returns (bool) {
        bool exists = false;
        for (uint256 i = 0; i < designatedProviders.length; i++) {
            if (designatedProviders[i] == provider) {
                exists = true;
            }
        }
        return exists;
    }

    function approveCloseOwner() public isOwner {
        ownerApprovedClose = true;
    }

    function approveCloseRegulatoryEntity() public isRegulatoryEntity {
        regulatoryEntityApprovedClose = true;
    }

    function selfdestructConstruction() internal {
        emit ConstructionSelfDestructed(
            name,
            lineOfWork,
            description,
            address(this).balance
        );
        // Se transfieren la mitad de los fondos al contrato gobierno.
        payable(address(taxEntity)).transfer(address(this).balance / 2);
        // Se auto destruye el contrato, enviando los fondos restantes (la otra mitad) al dueno del contrato
        selfdestruct(owner);
    }
}

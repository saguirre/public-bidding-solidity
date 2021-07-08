const path = require('path');
const fs = require('fs');
const solc = require('solc');

const configPath = path.resolve(process.cwd(), 'config.json');
const projectFolder = process.cwd();
const contractFolderName = 'contracts';
const buildFolderName = 'build';
const contractFileName = 'ConstructionFactory.sol';
const contractName = contractFileName.replace('.sol', '');
const contractPath = path.resolve(projectFolder, contractFolderName, contractFileName);

const abiPath = path.resolve(projectFolder, buildFolderName, contractName + '_abi.json');
const bytecodePath = path.resolve(projectFolder, buildFolderName, contractName + '_bytecode.json');

const methods = {
    compile() {
        const sourcesContent = {};
        sourcesContent[contractName] = { content: fs.readFileSync(contractPath, 'utf8') };


        const compilerInputs = {
            language: "Solidity",
            sources: sourcesContent,
            settings: {
                optimizer: { "enabled": true, "runs": 200 },
                outputSelection: { "*": { "*": ["abi", "evm.bytecode"] } }
            }
        }

        const compiledContract = JSON.parse(solc.compile(JSON.stringify(compilerInputs),
            { import: getImports }));

        const contract = compiledContract.contracts[contractName][contractName];

        const abi = contract.abi;
        const bytecode = contract.evm;

        fs.writeFileSync(abiPath, JSON.stringify(abi, null, 2));
        fs.writeFileSync(bytecodePath, JSON.stringify(bytecode, null, 2));
    },
    async deploy() {
        const bytecode = JSON.parse(fs.readFileSync(bytecodePath, 'utf8')).bytecode;
        const abi = JSON.parse(fs.readFileSync(abiPath, 'utf8'));

        const accounts = await web3.eth.getAccounts();

        try {
            const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
            const result = await new web3.eth.Contract(abi).deploy({
                data: '0x' + bytecode.object,
                arguments: [config.regulatoryEntityAddress, config.taxEntityAddress]
            })
                .send({
                    gas: '3000000',
                    from: process.env.ACCOUNT
                });

            config.constructionFactoryAddress = result.options.address;
            fs.writeFileSync(configPath, JSON.stringify(config, null, 2));

        } catch (error) {
            console.log(error);
        }
    },
    getContract() {
        const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
        const abi = JSON.parse(fs.readFileSync(abiPath, 'utf8'));

        return new web3.eth.Contract(abi, config.constructionFactoryAddress);
    }
}

module.exports = { ...methods }

function getImports(dependency) {
    switch (dependency) {
        case 'RegulatoryEntity.sol':
            return { contents: fs.readFileSync(path.resolve(projectFolder, contractFolderName, 'RegulatoryEntity.sol'), 'utf-8') }
        case 'TaxEntity.sol':
            return { contents: fs.readFileSync(path.resolve(projectFolder, contractFolderName, 'TaxEntity.sol'), 'utf-8') }
        case 'CivilRegistry.sol':
            return { contents: fs.readFileSync(path.resolve(projectFolder, contractFolderName, 'CivilRegistry.sol'), 'utf-8') }
        case 'Citizen.sol':
            return { contents: fs.readFileSync(path.resolve(projectFolder, contractFolderName, 'Citizen.sol'), 'utf-8') }
        case 'Tax.sol':
            return { contents: fs.readFileSync(path.resolve(projectFolder, contractFolderName, 'Tax.sol'), 'utf-8') }
        case 'Proposal.sol':
            return { contents: fs.readFileSync(path.resolve(projectFolder, contractFolderName, 'Proposal.sol'), 'utf-8') }
        case 'Construction.sol':
            return { contents: fs.readFileSync(path.resolve(projectFolder, contractFolderName, 'Construction.sol'), 'utf-8') }
        default:
            return { error: 'Error in the import' }
    }
}
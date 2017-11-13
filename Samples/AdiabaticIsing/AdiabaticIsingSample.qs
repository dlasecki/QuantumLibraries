// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

namespace Microsoft.Quantum.Samples.Ising {
    open Microsoft.Quantum.Primitive;
    open Microsoft.Quantum.Canon;

    // FIXME: UDTs loaded in from other assemblies need to be fully qualified for some
    //        reason, and so there's a lot of places where we have M.Q.C specified
    //        that should be removed.

    // We demonstrate one approach to adiabatic time evolution in this example.
    // In this example, we will use the function AdiabaticEvolution, which hides some underlying mechanics
    // We will use the Ising model we constructed in Microsoft.Quantum.Examples.Ising_1

    // We will be performing time-evolution using the SimulationAlgorithm 
    //     TimeDependentTrotterSimulationAlgorithm(trotterStepSize: Double, trotterOrder: Int)
    // We will index terms in the Hamiltonian using the EvolutionSet PauliEvolutionSet()


    // Adiabatic time-evolution requires a start Hamiltonian and an end Hamiltonian
    // The start Hamiltonian will be OneSiteGenSys(idxPauli: Int, nQubits: Int, hC: (Int -> Double))
    // The end Hamiltonian will be TwoSiteGenIdx(idxPauli: Int, nSites: Int, idxQubit : Int , jC: (Int -> Double))

    /// # Summary
    /// TODO
    function StartEvoGen(nSites: Int, hX: (Int -> Double)) : EvolutionGenerator {
        let XGenSys = OneSiteGenSys(1, nSites, hX);
        return EvolutionGenerator(PauliEvolutionSet(), XGenSys);
    }
    function EndEvoGen(nSites: Int, jZ: (Int -> Double)) : EvolutionGenerator {
        let ZZGenSys = TwoSiteGenSys(3, nSites, jZ);
        return EvolutionGenerator(PauliEvolutionSet(), ZZGenSys);
    }


    /// The function AdiabaticEvolution uniformly interpolates between the start and the end Hamiltonians.
    function IsingAdiabaticEvolution(nSites: Int, adiabaticTime: Double, trotterStepSize: Double, trotterOrder: Int, hX: (Int -> Double), jZ: (Int -> Double) ) : (Qubit[] => () : Adjoint, Controlled) {
        let start = StartEvoGen(nSites, hX);
        let end = EndEvoGen(nSites, jZ);
        let simulationAlgorithmTimeDependent = TimeDependentTrotterSimulationAlgorithm(trotterStepSize, trotterOrder);
        /// The function AdiabaticEvolution uniformly interpolates between the start and the end Hamiltonians.
        return AdiabaticEvolution(adiabaticTime, start, end, simulationAlgorithmTimeDependent);
    }

    /// This initializes the qubits in an easy-to-prepare eigenstate of the initial Hamiltonian - ( X_0 + X_1 +... ) 
    operation Ising1DStatePrep(qubits : Qubit[]) : (){
        body{
            ApplyToEachAC(H, qubits);
        }
        adjoint auto
        controlled auto
        controlled adjoint auto
    }

    /// Let us consider adiabatic evolution to the Ising model with uniform couplings with coefficient amplitude
    /// For antiferromagnetic coupling, choose amplitude to be negative.
    function IsingUniformAdiabaticEvolution(nSites: Int, hXAmplitude: Double, jCAmplitude:Double, adiabaticTime: Double, trotterStepSize: Double, trotterOrder: Int) : (Qubit[] => () : Adjoint, Controlled) {
        let hX = GenerateUniformHCoupling( hXAmplitude, _);
        let jZ = GenerateUniform1DJCoupling(nSites, jCAmplitude, _);
        return IsingAdiabaticEvolution(nSites, adiabaticTime, trotterStepSize, trotterOrder, hX, jZ);
    }

    /// After adiabatic evolution, let us measure the state of each site.
    operation Ising1DAdiabaticAndMeasure(nSites : Int, hXAmplitude: Double, jCAmplitude:Double, adiabaticTime: Double, trotterStepSize: Double, trotterOrder: Int) : Result[]{
        body{
            mutable results = new Result[nSites];
            using (qubits = Qubit[nSites]) {
                Ising1DStatePrep(qubits);
                (IsingUniformAdiabaticEvolution(nSites, hXAmplitude, jCAmplitude, adiabaticTime, trotterStepSize, trotterOrder))(qubits);
                set results = MultiM(qubits);
                ResetAll(qubits);
            }
            return results;
        }
    }


    //////////////////////////////////////////////////////////////////////////
    // TODO: INSERT SECTION HEADER HERE //////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////

    /// We demonstrate another approach to adiabatic time evolution in this example.
    /// In this example, we will use the function simulationAlgorithmTimeDependent directly
    
    /// We will be performing time-evolution using the SimulationAlgorithm 
    ///     TimeDependentTrotterSimulationAlgorithm(trotterStepSize: Double, trotterOrder: Int)
    /// We will index terms in the Hamiltonian using the EvolutionSet PauliEvolutionSet()

    /// We will use the Ising model we constructed in Microsoft.Quantum.Examples.Ising_1
    /// Ising1DEvolutionGenerator(nSites : Int, hX: (Int -> Double),  jC: (Int -> Double)) : EvolutionGenerator
    
    /// We start by defining EvolutionSchedule, which is a time-dependent EvolutionGenerator
    function IsingEvolutionScheduleImpl(nSites: Int, hXInitial: Double, hXFinal: Double, jZFinal: Double, schedule: Double) : Microsoft.Quantum.Canon.GeneratorSystem {
        let hX = GenerateUniformHCoupling( hXFinal * schedule + hXInitial * ( 1.0 - schedule), _);
        let jZ = GenerateUniform1DJCoupling(nSites, schedule * jZFinal, _);

        let (evolutionSet, generatorSystem) = Ising1DEvolutionGenerator(nSites, hX, jZ);
        return generatorSystem;
    }
    function IsingEvolutionSchedule(nSites: Int, hXInitial: Double, hXFinal: Double, jZFinal: Double) : Microsoft.Quantum.Canon.EvolutionSchedule {
        let evolutionSet = PauliEvolutionSet();
        return Microsoft.Quantum.Canon.EvolutionSchedule(evolutionSet, IsingEvolutionScheduleImpl(nSites, hXInitial, hXFinal, jZFinal, _));
    }

    /// the type SimulationAlgorithmTimeDependent takes as input (Duration of simulation, an evolution schedule, qubits)
    /// and implements time-dependent unitary evolution over the schedule parameter in [0,1]
    operation IsingAdiabaticEvolution_2_Impl(nSites: Int, hXInitial: Double, hXFinal: Double, jZFinal: Double, adiabaticTime: Double, simulationAlgorithmTimeDependent: SimulationAlgorithmTimeDependent, qubits : Qubit[]) : () {
        body {
            let evolutionSchedule = IsingEvolutionSchedule(nSites, hXInitial, hXFinal, jZFinal);
            simulationAlgorithmTimeDependent(adiabaticTime, evolutionSchedule, qubits);
        }
        adjoint auto
        controlled auto
        controlled adjoint auto
    }

    /// Let us use the Trotter time-dependent simulation algorithm,
    function IsingAdiabaticEvolution_2(nSites: Int, hXInitial: Double, hXFinal: Double, jZFinal: Double, adiabaticTime: Double, trotterStepSize: Double, trotterOrder: Int) : (Qubit[] => () : Adjoint, Controlled) {
        
        let simulationAlgorithmTimeDependent = Microsoft.Quantum.Canon.TimeDependentTrotterSimulationAlgorithm(trotterStepSize, trotterOrder);
        
        return IsingAdiabaticEvolution_2_Impl(nSites, hXInitial, hXFinal, jZFinal, adiabaticTime, simulationAlgorithmTimeDependent, _);

    }

    /// After adiabatic evolution, let us measure the state of each site.
    operation Ising1DAdiabaticAndMeasure_2(nSites : Int, hXAmplitude: Double, jCAmplitude:Double, adiabaticTime: Double, trotterStepSize: Double, trotterOrder: Int) : Result[]{
        body{
            let hXFinal = Float(0);
            mutable results = new Result[nSites];
            using (qubits = Qubit[nSites]) {
                Ising1DStatePrep(qubits);
                (IsingAdiabaticEvolution_2(nSites, hXAmplitude, hXFinal, jCAmplitude, adiabaticTime, trotterStepSize, trotterOrder))(qubits);
                set results = MultiM(qubits);
                ResetAll(qubits);
            }
            return results;
        }
    }

}
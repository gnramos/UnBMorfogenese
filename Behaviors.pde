/** @file Behaviors.pde
 * Define os comportamentos possíveis.
 *
 * @author Guilherme N. Ramos (gnramos@unb.br)
 */

abstract class Behavior {
  boolean enabled;

  Behavior() {
    this.enabled = true;
  }
}

abstract class SteeringBehavior extends Behavior {
  Unnamed owner;
  float weight;

  SteeringBehavior(Unnamed owner, float weight) {
assert owner != null :
    "Não é possível criar SteeringBehavior sem owner.";
assert weight != 0 :
    "Não é possível criar SteeringBehavior com weight = 0.";

    this.owner = owner;
    this.weight = weight;
  }

  abstract PVector steeringForce();
}

static PVector computeSeekingForce(Physics2DComponent physics2D, PVector target) {
  if (target == null || physics2D == null) return new PVector();

  PVector force = PVector.sub(target, physics2D.position.location);
  force.normalize();
  force.mult(physics2D.maxSpeed());
  force.sub(physics2D.movement.velocity);
  return force;
}

static PVector computeFleeingForce(Physics2DComponent physics2D, PVector target) {
    PVector force = computeSeekingForce(physics2D, target);
    force.mult(-1);
    return force;
}

class FleeBehavior extends SteeringBehavior {
  PVector target;

  FleeBehavior(Unnamed owner, PVector target) {
    super(owner, Configs.Behavior.Steering.Weight.Flee);

    this.target = target;
  }

  PVector steeringForce() {
    if (!enabled) return new PVector();

    return computeFleeingForce(owner.body.physics2D, target);
  }
}

class SeekBehavior extends SteeringBehavior {
  PVector target;

  SeekBehavior(Unnamed owner, PVector target) {
    super(owner, Configs.Behavior.Steering.Weight.Seek);

    this.target = target;
  }

  PVector steeringForce() {
    if (!enabled) return new PVector();

    return computeSeekingForce(owner.body.physics2D, target);
  }
}

class WallAvoidanceBehavior extends SteeringBehavior {
  WallSensor sensor;

  WallAvoidanceBehavior(Unnamed owner, WallSensor sensor) {
    super(owner, Configs.Behavior.Steering.Weight.WallAvoidance);

    this.sensor = sensor;
  }

  boolean avoidingWalls() {
    return (sensor != null && sensor.enabled);
  }

  PVector computeAvoidanceForce() {
    PVector force = new PVector();

    if (avoidingWalls()) {
      sensor.read();
      if (sensor.obstacleLocation.mag() > 0) {
        // força deve ser proporcional na direção oposta ao obstáculo.
        if (sensor.obstacleLocation.x != 0) force.x = -sensor.range/sensor.obstacleLocation.x;
        if (sensor.obstacleLocation.y != 0) force.y = -sensor.range/sensor.obstacleLocation.y;
        if (sensor.obstacleLocation.z != 0) force.z = -sensor.range/sensor.obstacleLocation.z;
        force.mult(owner.body.physics2D.movement.velocity.mag());
      }
    }
    return force;
  }

  PVector steeringForce() {
    if (!enabled) return new PVector();

    return computeAvoidanceForce();
  }
}

class WanderingBehavior extends SteeringBehavior {
  WanderingBehavior(Unnamed owner) {
    super(owner, Configs.Behavior.Steering.Weight.Wandering);
  }

  PVector steeringForce() {
    if (!enabled) return new PVector();

    PVector force = PVector.random2D();
    force.normalize();
    return force;
  }
}

/*********/

class Steering {
  ArrayList<SteeringBehavior> behaviors;  

  Steering(ArrayList<SteeringBehavior> behaviors) {
assert behaviors != null : 
    "Não é possível criar Steering com ArrayList<SteeringBehavior> nulo.";

    this.behaviors = behaviors;
  }

  void accumulateForces(PVector runningTotal) {
    for (SteeringBehavior behavior : behaviors) {
      PVector force = behavior.steeringForce();
      force.mult(behavior.weight);
      if (!accumulateForce(runningTotal, force))
        break;
    }
  }

  boolean accumulateForce(PVector runningTotal, PVector forceToAdd) {
    float magnitudeRemaining = Configs.Behavior.Steering.Max.Force - runningTotal.mag();

    if (magnitudeRemaining <= 0) 
      return false;

    double magnitudeToAdd = forceToAdd.mag();

    if (magnitudeToAdd > magnitudeRemaining) {
      forceToAdd.normalize();
      forceToAdd.mult(magnitudeRemaining);
    }
    runningTotal.add(forceToAdd);

    return true;
  }
}


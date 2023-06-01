extends Control

var gen_targets:float = 1 :
	set(value):
		gen_targets = value
		%_gen_targets.text = str(value)
		%gen_targets.value = value

var effort_cutoff:float :
	set(value):
		effort_cutoff = value
		%_effort_cutoff.text = str(value)
		%effort_cutoff.value = value

var climb_factor:float :
	set(value):
		climb_factor = value
		%_climb_factor.text = str(value)
		%climb_factor.value = value

var climb_cutoff:float :
	set(value):
		climb_cutoff = value
		%_climb_cutoff.text = str(value)
		%climb_cutoff.value = value

var drop_factor:float :
	set(value):
		drop_factor = value
		%_drop_factor.text = str(value)
		%drop_factor.value = value

var drop_cutoff:float :
	set(value):
		drop_cutoff = value
		%_drop_cutoff.text = str(value)
		%drop_cutoff.value = value

var field_effort_factor:float :
	set(value):
		field_effort_factor = value
		%_field_effort_factor.text = str(value)
		%field_effort_factor.value = value

#var field_penalty_factor:float :
#	set(value):
#		field_penalty_factor = value
#		%_field_penalty_factor.text = str(value)
#		%field_penalty_factor.value = value



func _on_effort_cutoff_value_changed(value):
	effort_cutoff = value


func _on_climb_factor_value_changed(value):
	climb_factor = value


func _on_climb_cutoff_value_changed(value):
	climb_cutoff = value


func _on_drop_factor_value_changed(value):
	drop_factor = value


func _on_drop_cutoff_value_changed(value):
	drop_cutoff = value


func _on_field_effort_factor_value_changed(value):
	field_effort_factor = value


#func _on_field_penalty_factor_value_changed(value):
#	field_penalty_factor = value


func _on_gen_targets_value_changed(value):
	gen_targets = value
